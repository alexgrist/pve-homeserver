# pve-homeserver

Terraform + Ansible for my Proxmox homelab. Terraform creates the LXCs, Ansible configures them.

## Prerequisites:

- Proxmox VE 8.4+ with API access
- OpenTofu >= 1.12
- 1Password CLI
- Proxmox API token with container creation permissions, stored as `PROXMOX_VE_API_TOKEN` in your shell

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill it in.
2. `terraform init && terraform validate && terraform plan -out planout`
3. Review the plan, then `terraform apply planout`.

Set the Proxmox token in your current session — the bpg/proxmox provider reads it from the environment, so it never touches a `.tfvars` file or Terraform state:

```powershell
$env:PROXMOX_VE_API_TOKEN = "<token-id>!<secret>"
```

Local state is the default. Backblaze B2 settings are provided through the ignored `backend-b2.hcl` file; credentials come from environment variables or a secret manager (1Password).

## Container definitions

Each container is defined as a YAML file under `terraform/environments/production/containers`.
The playbook in `local.yml` applies a `common` role to every host and then a role named after the hostname, so each container gets its own config on top of the shared baseline.
