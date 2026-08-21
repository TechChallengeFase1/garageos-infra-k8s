# Namespace da aplicacao.
#
# A infraestrutura entrega o namespace vazio; o repo garageos-app aplica dentro
# dele o Deployment, Service, ConfigMap, Secret e HPA. E a fronteira entre os
# dois repositorios.
#
# Unico arquivo aproveitado do projeto anterior sem reescrita: o recurso
# `kubernetes_namespace` e do provider do Kubernetes, nao da AWS, entao vale
# igual no EKS e no kind. So o `depends_on` mudou - antes apontava para o
# cluster kind.

resource "kubernetes_namespace" "garageos" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of"    = "garageos"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Espera os nos existirem. Sem isso o Terraform tenta criar o namespace assim
  # que o control plane responde, o que funciona - mas deixa o namespace pronto
  # antes de haver onde rodar pod, escondendo falhas do node group ate o
  # primeiro deploy.
  depends_on = [aws_eks_node_group.main]
}
