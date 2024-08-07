#!/bin/bash

export service="devkit"
export domain="punkerside.io"
export AWS_DEFAULT_REGION="us-east-1"

# eliminando repositorio
aws ecr delete-repository --repository-name ${service} --region ${AWS_DEFAULT_REGION} --force

# eliminando bucket
bucketName=$(aws s3api list-buckets --query "Buckets[].Name" | jq -r .[] | grep ${service})
echo ${bucketName}
aws s3 rm --recursive s3://${bucketName}/
aws s3api delete-bucket --bucket ${bucketName} --region ${AWS_DEFAULT_REGION}