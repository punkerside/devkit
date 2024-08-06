service = devkit
project = punkerside
env     = lab
domain  = punkerside.io

export AWS_DEFAULT_REGION=us-east-1

base:
	@docker build -t $(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}-${service}:latest .

release:
	@aws ecr create-repository --repository-name ${project}-${env}-${service} --image-tag-mutability MUTABLE --image-scanning-configuration scanOnPush=false | true
	@aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin $(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr."${AWS_DEFAULT_REGION}".amazonaws.com
	@docker push $(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}-${service}:latest

init:
	@cd terraform/ && terraform init

plan:
	@cd terraform/ && terraform plan -var "service=${service}" -var "project=${project}" -var "env=${env}" -var "domain=${domain}"

apply:
	@cd terraform/ && terraform apply -var "service=${service}" -var "project=${project}" -var "env=${env}" -var "domain=${domain}"

destroy:
	@cd terraform/ && terraform destroy -var "service=${service}" -var "project=${project}" -var "env=${env}" -var "domain=${domain}"