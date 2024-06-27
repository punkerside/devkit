service = devkit
project = punkerside
env     = lab

export AWS_DEFAULT_REGION=us-east-1

base:
	@docker build -t ${service}-${env}-${project} .

init:
	@cd terraform/ && terraform init

plan:
	@cd terraform/ && terraform plan -var "service=${service}" -var "project=${project}" -var "env=${env}"