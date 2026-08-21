# ─── Roles de servico do EKS ──────────────────────────────────────────────────
#
# Duas roles distintas, com finalidades diferentes:
#
#   cluster  vestida pelo CONTROL PLANE (servico eks.amazonaws.com) para criar
#            ENIs, load balancers e outros recursos em nome do cluster.
#
#   nodes    vestida pelas INSTANCIAS EC2 (servico ec2.amazonaws.com) para se
#            registrarem no cluster, configurarem rede de pods e baixarem
#            imagens.
#
# Confundir as duas e um erro comum: o cluster nao consegue se registrar como
# no, e o no nao consegue administrar o cluster.

# ── Role do control plane ─────────────────────────────────────────────────────

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.name}-eks-cluster"
  description        = "Vestida pelo control plane do EKS"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── Role dos nos ──────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "nodes_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nodes" {
  name               = "${local.name}-eks-nodes"
  description        = "Vestida pelas instancias EC2 que formam o node group"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume.json
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = {
    # Permite o no se registrar no cluster e reportar estado
    worker = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    # CNI da AWS: atribui IPs da VPC aos pods
    cni = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    # Baixar imagens do ECR (a imagem da API vem do Docker Hub, mas addons da
    # AWS como coredns e kube-proxy vem do ECR publico)
    ecr = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    # Acesso via Session Manager, para depurar um no sem abrir porta SSH
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

# ─── Provedor OIDC do cluster (IRSA) ──────────────────────────────────────────
#
# Alem do escopo do checklist da Fase 3, incluido aqui de proposito: e o que
# permite um ServiceAccount do Kubernetes assumir uma role da AWS sem chave
# estatica - o mesmo principio do OIDC do GitHub Actions, aplicado dentro do
# cluster.
#
# A Fase 4 depende disso para tirar os segredos do k8s/secret.yaml do Git e
# ler direto do Secrets Manager. Criar agora evita um segundo apply no cluster
# mais tarde. Nao tem custo.

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${local.name}-irsa"
  }
}
