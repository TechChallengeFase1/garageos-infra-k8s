# ─── Quem pode usar kubectl neste cluster ─────────────────────────────────────
#
# Substitui o ConfigMap aws-auth. Cada acesso e um recurso da AWS, criado pelo
# Terraform e validado na criacao - um ARN errado falha no apply em vez de
# inutilizar o cluster silenciosamente.
#
# Sao duas partes por principal:
#   access_entry              registra QUEM e (o principal IAM)
#   access_policy_association diz O QUE ele pode fazer (a policy do EKS)
#
# Registrar a entry sem associar a policy cria um acesso que autentica mas nao
# autoriza nada - o kubectl conecta e recebe Forbidden em tudo.

# ── A role do CI ──────────────────────────────────────────────────────────────
# Necessaria porque bootstrap_cluster_creator_admin_permissions esta desligado:
# sem esta entrada, a propria pipeline que criou o cluster nao conseguiria
# aplicar os manifestos da aplicacao depois.

resource "aws_eks_access_entry" "ci" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.github_actions_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ci" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ci]
}

# ── Administradores humanos ───────────────────────────────────────────────────
# Sem pelo menos um destes, ninguem consegue rodar kubectl da propria maquina.

resource "aws_eks_access_entry" "admins" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admins" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admins]
}
