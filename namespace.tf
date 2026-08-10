# Namespace da aplicacao (base provisionada por IaC).
resource "kubernetes_namespace" "garageos" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "garageos"
    }
  }

  depends_on = [kind_cluster.garageos]
}
