variable "aws_region" {
  description = "Regiao. A mesma do bootstrap - a VPC nao atravessa regioes."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo dos recursos"
  type        = string
  default     = "garageos"
}

variable "namespace" {
  description = "Namespace onde a aplicacao sera implantada pelo repo garageos-app"
  type        = string
  default     = "garageos"
}

variable "kubernetes_version" {
  description = <<-EOT
    Versao do Kubernetes do control plane. 1.36 e a padrao da AWS hoje.
    ATENCAO: o kubectl local precisa estar a no maximo 1 minor de distancia.
  EOT
  type        = string
  default     = "1.36"
}

variable "node_instance_type" {
  description = <<-EOT
    Tipo das instancias dos nos.

    t3.small (2 vCPU, 2 GB) suporta ate 11 pods por no - limite de ENI, nao de
    memoria. Com 2 nos sao 22 pods: cerca de 7 do sistema (coredns, aws-node,
    kube-proxy, metrics-server) e folga para os 10 replicas maximos do HPA.

    t3.medium dobraria a folga e o custo (~US$ 60/mes contra ~US$ 30).
  EOT
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Quantidade inicial de nos. 2 para haver no em cada AZ."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimo de nos"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = <<-EOT
    Maximo de nos. Nao ha Cluster Autoscaler instalado: este teto e o limite
    para crescimento manual, nao automatico. O HPA escala PODS, nao nos.
  EOT
  type        = number
  default     = 4
}

variable "admin_principal_arns" {
  description = <<-EOT
    Principais IAM que recebem acesso de administrador no cluster, via Access
    Entry. A role do CI e adicionada automaticamente e nao precisa estar aqui.

    Sem pelo menos um ARN valido nesta lista, ninguem consegue usar kubectl a
    partir da maquina local.
  EOT
  type        = list(string)
  default     = ["arn:aws:iam::266380777968:user/AdministratorAccess"]
}

variable "metrics_server_version" {
  description = "Versao do chart Helm do metrics-server"
  type        = string
  default     = "3.12.2"
}
