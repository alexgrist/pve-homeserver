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
  description = "The role tags associated with the container"
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  description = "The descriptive tags that never drive container replacement"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for tag in var.extra_tags :
      tag == lower(tag) && can(regex("^[a-z0-9][a-z0-9_-]*$", tag))
    ])
    error_message = "Extra tags must be lowercase alphanumerics, or contain - and _."
  }

  validation {
    condition     = length(setintersection(var.tags, var.extra_tags)) == 0
    error_message = "Extra tags must not duplicate role tags."
  }
}

variable "hostname" {
  description = "The hostname of the container"
  type        = string
}

variable "protection" {
  description = "Whether to enable pve protection for the container"
  type        = bool
  default     = false
}

variable "data_tier" {
  description = "Whether the container owns data volumes for other containers instead of running services"
  type        = bool
  default     = false
}

variable "started" {
  description = "Whether to start the container"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Whether to start the container when the host boots"
  type        = bool
  default     = true
}

variable "ssh_key" {
  description = "The SSH public key used to access the container"
  type        = string
  sensitive   = true
}

variable "template" {
  description = "The OS template the container is created from"
  type        = string

  validation {
    condition     = length(trimspace(var.template)) > 0
    error_message = "The container definition must have a template."
  }
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

variable "mounts" {
  description = "Additional volumes or host bind mounts exposed inside the container"
  type = list(object({
    volume        = string
    path          = string
    size          = optional(string)
    backup        = optional(bool, false)
    read_only     = optional(bool, false)
    acl           = optional(bool, false)
    quota         = optional(bool, false)
    replicate     = optional(bool, true)
    shared        = optional(bool, false)
    mount_options = optional(list(string))
    idmap         = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for mount in var.mounts :
      length(mount.volume) > 0 && startswith(mount.path, "/")
    ])
    error_message = "Each mount requires a non-empty volume and a path that starts with '/'."
  }

  validation {
    condition = alltrue([
      for mount in var.mounts :
      startswith(mount.volume, "/") ? mount.size == null : true
    ])
    error_message = "Bind mounts (absolute host paths) must not set 'size'; it only applies to storage-backed volumes."
  }
}
