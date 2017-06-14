# This makefile contains some convenience commands for deploying and publishing.

# For example, to build and run the docker container locally, just run:
# $ make run SERVICE=products

# or to publish the :latest version to the specified registry as :1.0.0, run:
# $ make publish version=1.0.0

# local testing with make run
# NAMESPACE = microservices/
# REGISTRY = 000000000000.dkr.ecr.us-west-2.amazonaws.com
# VERSION = latest

name = ${NAMESPACE}${SERVICE}
registry = ${REGISTRY}
version ?= ${VERSION}

help:
	@echo "  ecr_login: Login to AWS ECR"
	@echo "  binary: Build the golang binary"
	@echo "  image: Build the docker image"
	@echo "  publish: Push the VERSION tag docker image to ECR"

all: binary image ecr_login publish clean

binary:
	$(call blue, "Building Linux binary ready for containerisation...")
	docker run --rm -i -v "${GOPATH}":/gopath -v "$(CURDIR)/${SERVICE}":/app -e "GOPATH=/gopath" -w /app golang:1.7 sh -c 'CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o app'

image: binary
	$(call blue, "Building docker image...")
	docker build -t ${name}:${version} ${SERVICE}
	$(MAKE) clean

run: image
	$(call blue, "Running Docker image locally...")
	docker run -i -t --rm -P ${name}:${version}

	@echo "  pub"

ecr_login:
	@$(shell sudo aws ecr get-login --profile=${PROFILE} --region=${REGION})

publish:
	$(call blue, "Publishing Docker image to registry...")
	docker tag ${name}:${version} ${registry}/${name}:${version}
	docker push ${registry}/${name}:${version}

clean:
	@rm -f ${SERVICE}/app

define blue
	@tput setaf 6
	@echo $1
	@tput sgr0
endef
