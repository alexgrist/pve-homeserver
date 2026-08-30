# pve-homeserver

Terraform configs for my Proxmox homelab. Deploys LXCs using the bpg/proxmox provider.

## Prerequisites:

- Proxmox VE 8.4+ with API access
- OpenTofu >= 1.12
- Proxmox API token with container creation permissions
- LXC template (e.g., Debian 12, Ubuntu 24.04)

## Usage

1. Create `terraform.tfvars` with proxmox API settings.
2. Run: `terraform init && terraform validate && terraform plan`
3. Check the plan output (or output to a file with `-out planout`)
4. Apply with `terraform apply` (with `planout` if using file output)

## Example `terraform.tfvars`
```hcl
pve_endpoint  = "https://10.0.0.1:8006"
pve_api_token = "token-id!secret"
pve_node      = "pve"
pve_datastore = "local-lvm"
```
