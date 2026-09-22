
# SSH public key added to authorized_keys
ephemeral "onepassword_item" "deploy_key" {
  vault = var.op_vault
  title = "Deploy Key"
}

# SSH private deploy key used for ansible-pull to clone the git repo
ephemeral "onepassword_item" "git_deploy_key" {
  vault = var.op_vault
  title = "Github Deploy Key"
}

# Ansible Vault password used to encrypt/decrypt secrets
ephemeral "onepassword_item" "vault_password" {
  vault = var.op_vault
  title = "Ansible Vault"
}
