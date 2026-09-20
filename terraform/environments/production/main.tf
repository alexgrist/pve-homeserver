locals {
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

  hostname  = each.key
  tags      = each.value.tags
  template  = each.value.template
  distro    = each.value.distro
  resources = each.value.resources
  disk      = each.value.disk
  network   = each.value.network
}
