
# SSH public key added to authorized_keys
ephemeral "onepassword_item" "deploy_key" {
  vault = var.op_vault
  title = "LXC Deploy Key"
}
