service = devkit
project = punkerside
env     = lab

base:
	docker build -t ${service}-${env}-${project} .