
# SSH public key added to authorized_keys
ephemeral "onepassword_item" "admin_key" {
  vault = var.op_vault
  title = "LXC Development Key"
}
