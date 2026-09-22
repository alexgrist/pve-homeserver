terraform {
  required_version = ">= 1.12.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.113.1"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = ">= 3.3.1"
    }
  }
}
