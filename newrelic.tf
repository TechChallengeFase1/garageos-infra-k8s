# ─── Observabilidade do cluster ──────────────────────────────────────────────
#
# O agente .NET dentro dos pods ja reporta APM, traces e logs da APLICACAO.
# O que falta, e que o enunciado pede, e o outro lado: "consumo de recursos do
# Kubernetes (CPU, memoria)" - dado do CLUSTER, nao da aplicacao.
#
# Isso vem do nri-bundle, um chart guarda-chuva que agrupa varios componentes.
# Nem todos sao ligados aqui, e a razao e concreta: cada no t3.small tem cerca
# de 1,4 GB alocavel e ja opera perto de 56% so com a aplicacao. Ligar o pacote
# inteiro derrubaria pods por falta de memoria.

data "aws_secretsmanager_secret_version" "app" {
  secret_id = data.aws_ssm_parameter.app_secret_arn.value
}

locals {
  newrelic_license_key = jsondecode(data.aws_secretsmanager_secret_version.app.secret_string).newRelicLicenseKey
}

resource "helm_release" "newrelic" {
  name             = "newrelic-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  create_namespace = true

  # O chart baixa varias imagens; 10 minutos cobre com folga.
  timeout = 600
  wait    = true

  set_sensitive {
    name  = "global.licenseKey"
    value = local.newrelic_license_key
  }

  set {
    name = "global.cluster"
    # Mesmo nome do cluster na AWS, para as metricas casarem com a entidade
    # certa na interface do New Relic.
    value = aws_eks_cluster.main.name
  }

  # Reduz drasticamente o volume enviado: coleta as metricas essenciais e
  # descarta as de granularidade fina. Sem isto, um cluster pequeno consome a
  # cota de 100 GB/mes do free tier em poucos dias.
  set {
    name  = "global.lowDataMode"
    value = "true"
  }

  # ── O que fica ligado ──────────────────────────────────────────────────────

  # O coletor propriamente dito: CPU, memoria, disco e rede de nos, pods e
  # containers. E o que atende ao requisito.
  set {
    name  = "infrastructure.enabled"
    value = "true"
  }

  # Traduz objetos do Kubernetes (Deployment, HPA, Job) em metricas. O
  # componente acima depende dele para saber o estado desejado contra o real -
  # sem ele nao ha "2 de 4 replicas prontas", so contagem de containers.
  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  # Injeta identificadores do cluster nos pods da aplicacao, ligando cada
  # transacao do APM ao pod e ao no que a atendeu. E o que permite ir de uma
  # requisicao lenta ate o no que estava sob pressao.
  set {
    name  = "webhook.enabled"
    value = "true"
  }

  # ── O que fica desligado, e por que ────────────────────────────────────────

  # Os logs da aplicacao JA sao encaminhados pelo agente .NET, com trace.id em
  # cada linha. Ligar aqui duplicaria o mesmo dado e o custo de ingestao.
  set {
    name  = "logging.enabled"
    value = "false"
  }

  # Continuous profiling: excelente ferramenta, memoria demais para t3.small.
  set {
    name  = "newrelic-pixie.enabled"
    value = "false"
  }
  set {
    name  = "pixie-chart.enabled"
    value = "false"
  }

  # Nao ha Prometheus no cluster para raspar.
  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  # Eventos do Kubernetes sao uteis, mas nao sao requisito e custam ingestao.
  set {
    name  = "nri-kube-events.enabled"
    value = "false"
  }

  # Mesma razao do namespace e do metrics-server: os nos precisam existir antes.
  depends_on = [
    aws_eks_node_group.main,
    aws_eks_access_policy_association.ci,
  ]
}
