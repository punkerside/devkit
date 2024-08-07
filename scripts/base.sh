#!/bin/bash

export service="devkit"
export domain="punkerside.io"
export AWS_DEFAULT_REGION="us-east-1"

# compilando imagen de jenkins
docker build -t $(aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${service}:latest -f docker/Dockerfile.jenkins .

# creando repositorio
aws ecr create-repository --repository-name ${service} --image-tag-mutability MUTABLE --image-scanning-configuration scanOnPush=false --region ${AWS_DEFAULT_REGION} | true

# iniciando sesion en ecr
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin $(aws sts get-caller-identity | jq -r .Account).dkr.ecr."${AWS_DEFAULT_REGION}".amazonaws.com

# publicando imagen de jenkins
docker push $(aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${service}:latest

# creando bucket para el estado de terraform
aws s3api create-bucket --bucket ${service}-$(uuidgen) --region ${AWS_DEFAULT_REGION}