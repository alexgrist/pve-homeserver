variable "pve_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  sensitive   = true
}

variable "pve_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "pve_datastore" {
  description = "Datastore for container storage"
  type        = string
  default     = "local-lvm"
}

variable "op_vault" {
  description = "1Password vault name where secrets are stored"
  type        = string
  default     = "Homelab"
}
