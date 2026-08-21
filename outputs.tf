output "ambiente" {
  description = "Ambiente derivado do workspace do Terraform"
  value       = local.env
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint do API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Versao do Kubernetes em execucao"
  value       = aws_eks_cluster.main.version
}

output "namespace" {
  description = "Namespace onde o garageos-app deve implantar"
  value       = kubernetes_namespace.garageos.metadata[0].name
}

output "node_security_groups" {
  description = "Security Groups anexados aos nos, incluindo o cracha de acesso ao RDS"
  value       = aws_launch_template.nodes.vpc_security_group_ids
}

output "oidc_provider_arn" {
  description = "Provedor OIDC do cluster, para roles IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "configurar_kubectl" {
  description = "Comando para acessar o cluster da sua maquina"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}
