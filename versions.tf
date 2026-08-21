terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    # Usado apenas para ler o thumbprint do certificado do emissor OIDC do
    # cluster, em iam.tf.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket       = "garageos-tfstate-266380777968"
    key          = "k8s/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = local.env
      ManagedBy   = "terraform"
      Source      = "garageos-infra-k8s"
    }
  }
}

locals {
  env  = terraform.workspace == "default" ? "producao" : terraform.workspace
  name = "${var.project}-${local.env}"
}

# ─── Providers que falam com o cluster ────────────────────────────────────────
#
# Configurados a partir do cluster criado NESTE mesmo apply. O bloco `exec`
# resolve o token so na hora de aplicar, chamando a AWS CLI - diferente do data
# source `aws_eks_cluster_auth`, cujo token de 15 minutos pode expirar no meio
# de um apply longo (e o do EKS e longo).
#
# SE O PRIMEIRO APPLY FALHAR com erro de conexao tipo
# `dial tcp 127.0.0.1:80: connect: connection refused`, e porque o Terraform
# tentou avaliar estes providers antes de o cluster existir. Nesse caso, crie a
# base primeiro e rode de novo:
#
#   terraform apply -target=aws_eks_node_group.main
#   terraform apply
#
# Nao e erro de configuracao - e a limitacao conhecida de configurar um
# provider a partir de recursos do mesmo apply.

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name, "--region", var.aws_region]
    }
  }
}
