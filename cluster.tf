# ─── Cluster EKS ──────────────────────────────────────────────────────────────
#
# Substitui o `kind_cluster` do projeto anterior. A diferenca conceitual: no
# kind o cluster inteiro era um container na maquina; aqui o control plane
# (API server, etcd, scheduler) e gerenciado pela AWS, invisivel, e os nos sao
# instancias EC2 na sua VPC.
#
# CUSTO: o control plane cobra ~US$ 0,10/hora a partir do momento em que sobe,
# com zero ou com mil pods. Sao ~US$ 73/mes. Rode `terraform destroy` fora das
# janelas de trabalho.
#
# TEMPO: ~10 a 15 minutos para criar. A pipeline parece travada; e normal.

resource "aws_eks_cluster" "main" {
  name     = local.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  access_config {
    # "API" e o que atende ao requisito "nao utilizar aws-auth".
    #
    # Historicamente o EKS mapeava IAM para usuario do Kubernetes por um
    # ConfigMap chamado aws-auth, editado a mao e famoso por inutilizar
    # clusters quando salvo errado - nao havia validacao, e um erro de
    # digitacao tirava o acesso de todo mundo, sem volta.
    #
    # Com "API", o mapeamento vira recurso da AWS (os Access Entries em
    # access-entries.tf), versionado no Terraform e validado na criacao.
    # O modo "API_AND_CONFIG_MAP" ainda aceitaria o ConfigMap; "API" o
    # desabilita por completo.
    authentication_mode = "API"

    # Desligado de proposito. Quando ligado, quem cria o cluster ganha um
    # Access Entry implicito de administrador - e como o CI e quem cria, uma
    # entrada explicita para a mesma role falharia com ResourceInUseException.
    # Aqui todo acesso e declarado, sem excecao invisivel.
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    # As ENIs do control plane ficam nas 4 subnets, atendendo as 2 AZs.
    subnet_ids = concat(local.public_subnet_ids, local.private_subnet_ids)

    # Publico: necessario para o kubectl da sua maquina e do runner do GitHub.
    # Privado: faz o trafego dos nos ao API server ficar dentro da VPC.
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Logs do control plane no CloudWatch. Mantidos enxutos: "api" e
  # "authenticator" sao os que respondem "por que meu kubectl foi negado?".
  # Ligar os cinco tipos gera volume e custo de CloudWatch sem necessidade.
  enabled_cluster_log_types = ["api", "authenticator"]

  # Sem isso o cluster pode ser criado antes de a role ter a policy, e a
  # criacao falha.
  depends_on = [aws_iam_role_policy_attachment.cluster]

  tags = {
    Name = local.name
  }
}
