resource "proxmox_virtual_environment_container" "couchdb" {
  description = "CouchDB - NoSQL database"
  tags        = ["database", "nosql"]

  node_name     = var.pve_node
  start_on_boot = true
  started       = true

  unprivileged = true

  initialization {
    hostname = "couchdb"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  cpu {
    cores = 1
  }

  disk {
    datastore_id = var.pve_datastore
    size         = 8
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  network_interface {
    bridge  = "vmbr0"
    name    = "eth0"
    vlan_id = 10
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }
}
