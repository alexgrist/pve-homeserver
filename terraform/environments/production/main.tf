locals {
  deploy_public_key = trimspace(
    file("${path.root}/keys/deploy.pub")
  )
}

module "containers" {
  source = "../../modules/containers"

  containers_dir = "${path.module}/containers"

  pve = {
    node      = var.pve_node
    datastore = var.pve_datastore
  }

  ssh_key = local.deploy_public_key
}
