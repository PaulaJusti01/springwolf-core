Boa! 🎯 Agora que você tirou o flavor, a regra é simples:
👉 você só pode declarar no main.tf as variáveis que realmente estão sendo exportadas pelo read-config como outputs.

Pelos prints que você me mostrou, os outputs confirmados do read-config são:

aws-account

aws-account-name

aws-region

sigla

project-name

pipeline-type

pipeline-version

destroy

timestamp

model-name

model-path

lotus-s3-bucket

table-name

spec-s3bucket

spec-db-source-name

spec-db-corp-name

experiment-id

id-mrm

tech-team-email

(e aqueles de build: build-working-directory, build-python-version, build-architecture, etc., mas esses normalmente não entram no Terraform, e sim no CI/CD).


⚡️ Então no seu main.tf você vai precisar passar só os que o módulo lotus realmente espera.

Exemplo (ajustando para o módulo sagemaker que você mostrou antes):

module "lotus" {
  source  = "git::ssh://git@github.com/itau-corp/lotus-tf-modules.git//sagemaker?ref=v1.2.0"

  aws_account   = var.aws_account
  aws_region    = var.aws_region
  project_name  = var.project_name
  pipeline_type = var.pipeline_type
  pipeline_version = var.pipeline_version

  model_name    = var.model_name
  model_path    = var.model_path
  s3_bucket     = var.lotus_s3_bucket
  table_name    = var.table_name
  spec_s3bucket = var.spec_s3bucket
  spec_db_source_name = var.spec_db_source_name
  spec_db_corp_name   = var.spec_db_corp_name
  experiment_id = var.experiment_id
  id_mrm        = var.id_mrm
  tech_team_email = var.tech_team_email
}

> 🚨 Repara que eu tirei totalmente flavor_name, flavor_version, flavor_params porque eles não existem mais no config.yml nem no read-config.




---

👉 Minha sugestão prática: abra o variables.tf do módulo lotus/sagemaker que você está chamando. Ele mostra exatamente quais variáveis o módulo espera.
Aí você cruza com a lista acima e só passa essas.

Quer que eu liste aqui as variáveis olhando direto no seu read-config.yml + build-dependencies.yml, para já te devolver um main.tf final pronto sem flavor?

