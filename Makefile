# toolchains run through docker compose, wrap a command in an op session with OP_ENV
OP_ENV ?=
OP := $(if $(OP_ENV),op run --environment=$(OP_ENV) --,)

COMPOSE := docker compose run --rm
TOFU_ENV ?= development
ANSIBLE_ENV ?= development

# production targets the site playbook, development targets its test playbook
PLAYBOOK ?= $(if $(filter production,$(ANSIBLE_ENV)),site.yml,development.yml)

.DEFAULT_GOAL := help

.PHONY: help build tf-init tf-plan tf-apply tf-fmt inventory playbook playbook-local lint-ansible

help: ## list the targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk -F': *## ' '{printf "  %-16s %s\n", $$1, $$2}'

build: ## build the toolchain containers
	docker compose build

tf-init: ## initialise the tofu working directory
	$(OP) $(COMPOSE) tofu tofu -chdir=/workspace/environments/$(TOFU_ENV) init

tf-plan: ## create and save the execution plan
	$(OP) $(COMPOSE) tofu tofu -chdir=/workspace/environments/$(TOFU_ENV) plan -out planout

tf-apply: ## apply the saved execution plan
	$(OP) $(COMPOSE) tofu tofu -chdir=/workspace/environments/$(TOFU_ENV) apply "planout"

tf-fmt: ## check the tofu formatting
	$(COMPOSE) tofu tofu -chdir=/workspace/environments/$(TOFU_ENV) fmt -check

inventory: ## list the ansible inventory
	$(OP) $(COMPOSE) ansible ansible-inventory -i inventories/$(ANSIBLE_ENV)/hosts.proxmox.yml --list

playbook: ## push the ansible playbook
	$(OP) $(COMPOSE) ansible ansible-playbook -i inventories/$(ANSIBLE_ENV)/hosts.proxmox.yml playbooks/$(PLAYBOOK)

playbook-local: ## run the local test playbook in an ansible container
	$(OP) $(COMPOSE) ansible ansible-playbook -i inventories/development/local.yml playbooks/local.yml

lint-ansible: ## run ansible-lint on the playbooks and roles
	$(COMPOSE) ansible ansible-lint playbooks roles
