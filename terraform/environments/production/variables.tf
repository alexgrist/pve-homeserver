
variable "pve_endpoint" {
  description = "Proxmox API endpoint URL (e.g., https://192.168.1.100:8006/)"
  type        = string
}

variable "pve_node" {
  description = "Proxmox node name where the container will be created"
  type        = string
  default     = "pve"
}

variable "pve_datastore" {
  description = "Proxmox datastore ID used for container storage"
  type        = string
  default     = "local-lvm"
}
