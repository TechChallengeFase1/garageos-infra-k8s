# ─── O que os outros repositorios publicaram no quadro de avisos ──────────────
#
# Este repositorio nao cria rede nem banco. Ele descobre os dois pelo SSM:
#   - do bootstrap:        VPC e subnets
#   - do infra-database:   o "cracha" de acesso ao RDS
#
# E a dependencia declarada em codigo. Se o bootstrap ou o banco nao tiverem
# sido aplicados, o plan falha aqui com ParameterNotFound - o que e melhor do
# que criar um cluster que nao consegue falar com nada.

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/vpc/id"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/${var.project}/vpc/public-subnet-ids"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project}/vpc/private-subnet-ids"
}

data "aws_ssm_parameter" "github_actions_role_arn" {
  name = "/${var.project}/iam/github-actions-role-arn"
}

# Onde estao os segredos compartilhados da aplicacao. Usado em newrelic.tf
# para a license key de ingestao.
data "aws_ssm_parameter" "app_secret_arn" {
  name = "/${var.project}/app/secret-arn"
}

# O cracha criado pelo garageos-infra-database. Anexa-lo aos nos e o que da ao
# cluster acesso ao PostgreSQL - sem precisar saber IP de ninguem.
data "aws_ssm_parameter" "rds_client_sg_id" {
  name = "/${var.project}/${local.env}/rds/client-security-group-id"
}

# `nonsensitive()` porque o provider da AWS marca o valor de QUALQUER parametro
# do SSM como sensivel, inclusive os do tipo String. A precaucao faz sentido
# para SecureString, mas aqui os valores sao identificadores publicos - ID de
# VPC, de subnet, de Security Group e ARN de role. Sem isso, qualquer output
# que os referencie falha com "Output refers to sensitive values", e os IDs
# apareceriam como (sensitive value) no plano, deixando a revisao cega.
#
# A senha do banco NAO passa por aqui: ela fica no Secrets Manager, e o que se
# publica no SSM e apenas o ARN de onde busca-la.
locals {
  vpc_id                  = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
  public_subnet_ids       = split(",", nonsensitive(data.aws_ssm_parameter.public_subnet_ids.value))
  private_subnet_ids      = split(",", nonsensitive(data.aws_ssm_parameter.private_subnet_ids.value))
  github_actions_role_arn = nonsensitive(data.aws_ssm_parameter.github_actions_role_arn.value)
  rds_client_sg_id        = nonsensitive(data.aws_ssm_parameter.rds_client_sg_id.value)
}
