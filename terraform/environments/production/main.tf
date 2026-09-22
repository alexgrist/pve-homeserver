
locals {
  vault_password     = ephemeral.onepassword_item.vault_password.password
  deploy_private_key = ephemeral.onepassword_item.deploy_key.private_key
  deploy_public_key = trimspace(
    file("${path.root}/../../keys/deploy.pub")
  )
  git_deploy_key_private = ephemeral.onepassword_item.git_deploy_key.private_key

  # parse container yml definitions
  containers = {
    for filepath in fileset("${path.module}/containers", "*.yaml") :
    trimsuffix(filepath, ".yaml") => merge(
      # base structure
      {
        tags      = []
        template  = null
        distro    = null
        resources = null
        disk      = null
        network   = {}
      },

      yamldecode(file("${path.module}/containers/${filepath}")),
    )
  }
}

module "lxc" {
  source   = "../../modules/lxc-container"
  for_each = local.containers

  pve = {
    node      = var.pve_node
    datastore = var.pve_datastore
  }

  ssh_key   = local.deploy_public_key
  hostname  = each.key
  tags      = each.value.tags
  template  = each.value.template
  distro    = each.value.distro
  resources = each.value.resources
  disk      = each.value.disk
  network   = each.value.network
}

module "ansible" {
  source   = "../../modules/ansible-bootstrap"
  for_each = local.containers

  container_id = module.lxc[each.key].container_id
  container_ip = module.lxc[each.key].container_ip

  ssh_private_key        = local.deploy_private_key
  git_deploy_private_key = local.git_deploy_key_private
  git_repo_url           = var.git_repo_url
  vault_password         = local.vault_password
}

