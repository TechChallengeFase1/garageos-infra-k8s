# Ambiente de homologacao.
#
# ATENCAO: um segundo cluster significa um segundo control plane, e o control
# plane e o item mais caro da conta - ~US$ 73/mes CADA, ligado ou ocioso. Nao
# existe free tier para EKS.
#
# Com homolog e producao no ar ao mesmo tempo, o gasto passa de US$ 7/dia e os
# creditos acabam em duas semanas.
#
# Recomendacao: suba homolog apenas para provar que a pipeline de homologacao
# funciona (evidencia para o video e para a entrega), e destrua em seguida:
#
#   Actions > Terraform > Run workflow > ambiente: homolog, acao: destroy
#
# Um unico no basta para essa demonstracao.

node_instance_type = "t3.small"
node_desired_size  = 1
node_min_size      = 1
node_max_size      = 2
