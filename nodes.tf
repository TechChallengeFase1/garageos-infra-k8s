# ─── Onde os pods realmente rodam ─────────────────────────────────────────────
#
# O Launch Template existe por um motivo especifico: e a UNICA forma de anexar
# Security Groups adicionais a um managed node group.
#
# E preciso porque o acesso ao banco depende disso - o "cracha"
# (garageos-<env>-rds-client) criado no repo do banco tem que estar nos nos,
# senao o SG do RDS recusa a conexao.
#
# ARMADILHA: quando o node group usa Launch Template com
# `vpc_security_group_ids`, o EKS deixa de anexar o cluster security group
# automaticamente. Ele precisa ser listado a mao - sem ele os nos nao
# conseguem falar com o control plane e o node group nunca fica pronto.

resource "aws_launch_template" "nodes" {
  name_prefix = "${local.name}-node-"
  description = "Nos do EKS com o cracha de acesso ao RDS"

  vpc_security_group_ids = [
    # Obrigatorio: comunicacao no <-> control plane e no <-> no
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id,
    # O cracha: e isto que libera a porta 5432 do RDS
    local.rds_client_sg_id,
  ]

  metadata_options {
    http_endpoint = "enabled"
    # IMDSv2 obrigatorio. Fecha a classe de ataque em que um SSRF na aplicacao
    # le as credenciais da instancia pelo IMDSv1.
    http_tokens = "required"
    # 2 saltos: o pod roda em container, entao a resposta do IMDS precisa
    # atravessar uma camada de rede a mais que um processo no host.
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name}-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name}-ng"
  node_role_arn   = aws_iam_role.nodes.arn

  # Subnets PUBLICAS. Decisao tomada no bootstrap: sem NAT Gateway
  # (~US$ 32/mes), os nos precisam de rota propria para a internet para baixar
  # imagens e alcancar a API do EKS. Ficam com IP publico, protegidos pelos
  # Security Groups - nenhuma porta aberta para 0.0.0.0/0.
  #
  # Em producao real seriam subnets privadas atras de NAT.
  subnet_ids = local.public_subnet_ids

  instance_types = [var.node_instance_type]
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # Substitui um no por vez em atualizacoes, mantendo a aplicacao no ar.
  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  # As policies precisam existir ANTES de o no tentar se registrar, senao ele
  # sobe, falha a autenticacao e o node group fica em CREATE_FAILED.
  depends_on = [aws_iam_role_policy_attachment.nodes]

  tags = {
    Name = "${local.name}-ng"
  }
}
