# Ambiente de producao (branch main).
#
# CUSTO ESTIMADO com estes valores, ligado 24h:
#   control plane   ~US$ 73/mes  (fixo, independe de uso)
#   2x t3.small     ~US$ 30/mes
#   -------------------------------------------------
#   total           ~US$ 103/mes = ~US$ 3,40/dia
#
# Somado ao RDS, sao ~US$ 3,50/dia. Destrua fora das janelas de trabalho:
# o workflow tem `workflow_dispatch` com acao "destroy" para isso.

node_instance_type = "t3.small"
node_desired_size  = 2
node_min_size      = 2
node_max_size      = 4
