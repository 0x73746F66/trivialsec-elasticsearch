SHELL := /bin/bash
-include .env
export $(shell sed 's/=.*//' .env)
.ONESHELL: # Applies to every targets in the file!
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

init: ## Runs tf init tf
	cd plans
	terraform init -reconfigure -upgrade=true

output:
	cd plans
	terraform output linode_password

deploy: plan apply output ## tf plan and apply -auto-approve -refresh=true

plan: init ## Runs tf validate and tf plan
	cd plans
	terraform init -reconfigure -upgrade=true
	terraform validate
	terraform plan -no-color -out=.tfplan
	terraform show --json .tfplan | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > tfplan.json

apply: ## tf apply -auto-approve -refresh=true
	cd plans
	terraform apply -auto-approve -refresh=true .tfplan

destroy: init ## tf destroy -auto-approve
	cd plans
	terraform validate
	terraform plan -destroy -no-color -out=.tfdestroy
	terraform show --json .tfdestroy | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > tfdestroy.json
	terraform apply -auto-approve -destroy .tfdestroy

attach-firewall:
	curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer ${TF_VAR_linode_token}" \
		-X POST -d '{"type": "linode", "id": $(shell curl -s -H "Authorization: Bearer ${TF_VAR_linode_token}" https://api.linode.com/v4/linode/instances | jq -r '.data[] | select(.label=="prd-es.trivialsec.com") | .id')}' \
		https://api.linode.com/v4/networking/firewalls/${LINODE_FIREWALL}/devices

#####################
# Development Only
#####################
setup: ## Creates docker networks and volumes
	docker network create trivialsec 2>/dev/null || true
	docker volume create --name=elasticsearch 2>/dev/null || true

tfinstall:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(shell lsb_release -cs) main"
	sudo apt-get update
	sudo apt-get install -y terraform
	terraform -install-autocomplete || true

docker-clean: ## quick docker environment cleanup
	docker rmi $(docker images -qaf "dangling=true")
	yes | docker system prune
	sudo service docker restart

docker-purge: ## thorough docker environment cleanup
	docker rmi $(docker images -qa)
	yes | docker system prune
	sudo service docker stop
	sudo rm -rf /tmp/docker.backup/
	sudo cp -Pfr /var/lib/docker /tmp/docker.backup
	sudo rm -rf /var/lib/docker
	sudo service docker start

es-unknown-sources:
	curl --location --request GET 'http://elastic:${ELASTIC_PASSWORD}@localhost:9200/_search' --header 'Content-Type: application/json' --data-raw '{"query": {"match": {"assigner": "Unknown"}}}' | jq '.hits.hits[]._id'

es-cves:
	curl --location --request GET 'http://elastic:${ELASTIC_PASSWORD}@localhost:9200/cves/_stats' | jq -CS

update: ## pulls images
	docker-compose pull

up: update ## Starts latest container images
	docker-compose up -d

down: ## Bring down containers
	docker-compose down --remove-orphans
