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
  #
  # A dependencia da Access Entry NAO e opcional, e o motivo aparece so no
  # destroy: o Terraform destroi na ordem inversa da criacao. Sem declara-la,
  # ele fica livre para remover o acesso do CI ao cluster ANTES de remover o
  # namespace - e ai a propria pipeline perde a permissao e falha com
  # "namespaces \"garageos\" is forbidden".
  #
  # Declarando, a ordem fica garantida:
  #   criar   -> acesso, depois namespace
  #   destroir -> namespace, depois acesso
  depends_on = [
    aws_eks_node_group.main,
    aws_eks_access_policy_association.ci,
  ]
}
