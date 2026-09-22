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

variable "id" {
  description = "The ID of the container"
  type        = number
  default     = null
}

variable "description" {
  description = "The description of the container"
  type        = string
  default     = "Managed by Terraform"
}

variable "tags" {
  description = "The tags associated with the container"
  type        = list(string)
  default     = []
}

variable "hostname" {
  description = "The hostname of the container"
  type        = string
}

variable "ssh_key" {
  description = "The SSH public key used to access the container"
  type        = string
  sensitive   = true
}

variable "template" {
  description = "The template to use for the container"
  type        = string
}

variable "distro" {
  description = "The linux distribution of the container (ubuntu, debian, alpine)"
  type        = string

  validation {
    condition     = contains(["alpine", "archlinux", "centos", "debian", "fedora", "gentoo", "opensuse", "ubuntu", "unmanaged"], var.distro)
    error_message = "The distro must be one of: alpine, archlinux, centos, debian, fedora, gentoo, opensuse, ubuntu, unmanaged."
  }
}

variable "resources" {
  description = "The system resource allocation for the container"
  type = object({
    cores       = optional(number, 1)
    memory      = optional(number, 512)
    memory_swap = optional(number, 512)
  })
  default = null
}

variable "disk" {
  description = "The disk configuration for the container"
  type = object({
    size      = optional(number, 8)
    datastore = optional(string)
  })
  default = null
}

variable "network" {
  description = "The network configuration for the container"
  type = object({
    bridge = optional(string, "vmbr0")
    vlan   = optional(number)
  })
  default = {}
}
