# metrics-server: necessario para o Horizontal Pod Autoscaler (HPA) ler CPU/memoria.
# Instalado via Helm como recurso Terraform (sem local-exec).
# A flag --kubelet-insecure-tls e necessaria porque o kubelet do kind usa cert self-signed.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [kind_cluster.garageos]
}
