
resource "proxmox_virtual_environment_container" "this" {
  description = var.description
  tags        = var.tags

  node_name = var.pve.node
  vm_id     = var.id

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  wait_for_ip {
    ipv4 = true
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  disk {
    datastore_id = var.pve.datastore
    size         = var.disk.size
  }

  cpu {
    cores = var.resources.cores
  }

  memory {
    dedicated = var.resources.memory
    swap      = var.resources.memory_swap
  }

  network_interface {
    name    = "eth0"
    bridge  = var.network.bridge
    vlan_id = var.network.vlan
  }

  operating_system {
    template_file_id = var.template
    type             = var.distro
  }

  lifecycle {
    precondition {
      condition     = var.template != null && var.template != ""
      error_message = "'${var.hostname}' container definition must have a template."
    }

    precondition {
      condition     = var.distro != null && var.distro != ""
      error_message = "'${var.distro}' container definition must have a distro."
    }
  }
}

