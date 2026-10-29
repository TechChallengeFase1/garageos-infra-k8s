# Ingress controller da Fase 4.
#
# POR QUE UM INGRESS, E NAO UM LOADBALANCER POR SERVICO:
#
# Cada Service do tipo LoadBalancer cria um NLB proprio (~US$ 16/mes cada, mais
# 2 IPv4 publicos), e o terraform destroy nao remove nenhum deles - quem os
# criou foi o Kubernetes. Com 3 servicos seriam 3 NLBs para pagar e 3 chances
# de NLB orfao travando a destruicao da VPC. Com o Traefik ha UM NLB, e cada
# servico entra como Ingress ClusterIP com um prefixo de rota proprio
# (/os, /billing, /execucao).
#
# Por que Traefik: o ingress-nginx foi aposentado pelo projeto Kubernetes, e o
# AWS Load Balancer Controller exigiria IRSA e uma policy IAM gerenciada, que a
# role do CI nao pode criar (bootstrap/oidc.tf nao tem iam:CreatePolicy).
#
# ATENCAO NO DESTROY: este chart cria o NLB. O helm_release e destruido antes
# do node group (ordem inversa da criacao), o que apaga o Service e com ele o
# NLB. Mesmo assim, confira `aws elbv2 describe-load-balancers` vazio antes de
# destruir a VPC.

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = "traefik"
  create_namespace = true

  wait    = true
  timeout = 600

  values = [yamlencode({
    # Nome fixo do Deployment e do Service, para a tag do NLB ser previsivel:
    # o garageos-lambda-auth encontra o NLB por kubernetes.io/service-name.
    fullnameOverride = "traefik"

    deployment = { replicas = 1 }

    resources = {
      requests = { cpu = "50m", memory = "64Mi" }
      limits   = { memory = "192Mi" }
    }

    ingressClass = {
      enabled        = true
      isDefaultClass = true
    }

    providers = {
      kubernetesIngress = { enabled = true }
      kubernetesCRD     = { enabled = true }
    }

    # So a porta 80: o NLB nao tem certificado, e o TLS publico fica no API
    # Gateway (ADR 0003). Expor a 443 criaria um listener que ninguem atende.
    ports = {
      websecure = { expose = { default = false } }
    }

    # Mesmas anotacoes do Service da Fase 3 (garageos-app/k8s/api-service.yaml):
    # "nlb" e atendido pelo cloud controller que ja vem no EKS.
    service = {
      type = "LoadBalancer"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      }
      spec = { externalTrafficPolicy = "Local" }
    }
  })]

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_access_policy_association.ci,
  ]
}
