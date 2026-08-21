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
