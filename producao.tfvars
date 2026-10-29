# Ambiente de producao (branch main).
#
# CUSTO ESTIMADO com estes valores, ligado 24h:
#   control plane   ~US$ 73/mes  (fixo, independe de uso)
#   2x c7i-flex.large ~US$ 124/mes
#   NLB do Traefik    ~US$ 16/mes
#   -------------------------------------------------
#   total             ~US$ 213/mes = ~US$ 7/dia
#
# Pre-condicao da Fase 4 (ADR 0004 do garageos-app): 3 servicos com 2 replicas
# cada nao cabem em 2x t3.small, que ja operavam a ~56% de memoria com uma
# aplicacao so.
#
# POR QUE c7i-flex.large E NAO t3.medium: a conta esta no plano gratuito da
# AWS (contas criadas depois de jul/2025), que so lanca tipos elegiveis ao free
# tier. O t3.medium nao e - o node group fica em CREATING e o Auto Scaling
# registra "The specified instance type is not eligible for Free Tier". Entre os
# elegiveis, c7i-flex.large tem a mesma memoria do t3.medium (4 GB) e 29 pods
# por no. Lista atual:
#   aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true Destrua fora das janelas de trabalho:
# o workflow tem `workflow_dispatch` com acao "destroy" para isso.

node_instance_type = "c7i-flex.large"
node_desired_size  = 2
node_min_size      = 2
node_max_size      = 4

# Quem pode usar kubectl a partir da propria maquina.
#
# bootstrap_cluster_creator_admin_permissions esta desligado e o
# authentication_mode e "API": sem o ARN listado aqui, o kubectl autentica na
# AWS normalmente e o cluster responde Unauthorized - o que parece problema de
# credencial, mas e falta de Access Entry.
admin_principal_arns = [
  "arn:aws:iam::266380777968:user/AdministratorAccess",
  "arn:aws:iam::266380777968:user/joao",
]
