# ─── metrics-server ───────────────────────────────────────────────────────────
#
# O HPA le CPU e memoria pela Metrics API, que o Kubernetes NAO implementa por
# padrao. Sem o metrics-server, o HPA fica com <unknown>/70% nas metricas e
# nunca escala - o requisito "Cluster Kubernetes com escalabilidade" fica
# apenas declarado no YAML, sem funcionar.
#
# Tambem e o que alimenta `kubectl top nodes` e `kubectl top pods`, uteis na
# demonstracao ao vivo.
#
# DIFERENCA PARA A VERSAO ANTERIOR (kind): o arquivo antigo passava
# `--kubelet-insecure-tls`, porque o kubelet do kind usava certificado
# self-signed que o metrics-server recusava. No EKS o kubelet usa certificado
# assinado pela CA do proprio cluster, entao a flag foi removida - ela apenas
# desabilitaria a verificacao de TLS sem necessidade.

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"

  # O apply so retorna quando os pods estiverem prontos. Preferivel a descobrir
  # depois, no primeiro HPA que nao escala, que o chart subiu quebrado.
  wait    = true
  timeout = 300

  # Mesma razao do namespace.tf: sem a dependencia da Access Entry, o destroy
  # pode remover o acesso do CI ao cluster antes de desinstalar o chart, e o
  # Helm falha por falta de permissao.
  depends_on = [
    aws_eks_node_group.main,
    aws_eks_access_policy_association.ci,
  ]
}
