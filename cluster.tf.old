# Cluster Kubernetes local provisionado como recurso Terraform (IaC).
# Diferente do Docker Desktop, o kind exige mapear explicitamente o NodePort
# para o host via extra_port_mappings, para acessar a API em localhost:30080.
resource "kind_cluster" "garageos" {
  name           = var.cluster_name
  node_image     = var.node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # Expoe o NodePort da API (30080) em localhost:30080
      extra_port_mappings {
        container_port = var.api_node_port
        host_port      = var.api_node_port
        protocol       = "TCP"
      }
    }
  }
}
