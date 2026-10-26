variable "containers_dir" {
  description = "The directory of yml container definitions"
  type        = string
}

variable "pve" {
  description = "The target Proxmox host details"
  type = object({
    node      = string
    datastore = string
  })

  validation {
    condition     = length(var.pve.node) > 0 && length(var.pve.datastore) > 0
    error_message = "Both pve.node and pve.datastore must be non-empty strings."
  }
}

variable "ssh_key" {
  description = "The SSH public key used to access the containers"
  type        = string
  sensitive   = true
}
