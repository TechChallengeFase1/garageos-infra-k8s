# ─── O que este repositorio publica ───────────────────────────────────────────
#
# Consumido principalmente pelo garageos-app, cuja pipeline precisa saber em
# qual cluster e em qual namespace aplicar os manifestos. Sem isso o nome do
# cluster estaria escrito a mao no workflow da aplicacao, e um rename aqui
# quebraria o deploy la sem aviso.

resource "aws_ssm_parameter" "cluster_name" {
  name        = "/${var.project}/${local.env}/eks/cluster-name"
  description = "Nome do cluster, para `aws eks update-kubeconfig`"
  type        = "String"
  value       = aws_eks_cluster.main.name
}

resource "aws_ssm_parameter" "cluster_endpoint" {
  name  = "/${var.project}/${local.env}/eks/endpoint"
  type  = "String"
  value = aws_eks_cluster.main.endpoint
}

resource "aws_ssm_parameter" "namespace" {
  name        = "/${var.project}/${local.env}/eks/namespace"
  description = "Namespace onde o garageos-app deve aplicar os manifestos"
  type        = "String"
  value       = kubernetes_namespace.garageos.metadata[0].name
}

# Necessario para criar roles IRSA na Fase 4 (pods lendo o Secrets Manager
# sem chave estatica).
resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/${var.project}/${local.env}/eks/oidc-provider-arn"
  description = "ARN do provedor OIDC do cluster, para trust policies de IRSA"
  type        = "String"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# ─── Fase 4 ──────────────────────────────────────────────────────────────────

# Namespace de cada microsservico. O CD de cada repo le o seu daqui, no mesmo
# padrao do /eks/namespace acima.
resource "aws_ssm_parameter" "service_namespace" {
  for_each = kubernetes_namespace.servico

  name        = "/${var.project}/${local.env}/eks/namespace/${each.key}"
  description = "Namespace onde o garageos-${each.key}-service aplica os manifestos"
  type        = "String"
  value       = each.value.metadata[0].name
}

# "<namespace>/<service>" do Traefik. O garageos-lambda-auth usa isto para achar
# o NLB pela tag kubernetes.io/service-name, sem escrever o nome a mao.
resource "aws_ssm_parameter" "ingress_service_name" {
  name        = "/${var.project}/${local.env}/ingress/service-name"
  description = "Service do Traefik, no formato namespace/nome, para localizar o NLB"
  type        = "String"
  value       = "${helm_release.traefik.namespace}/traefik"
}
