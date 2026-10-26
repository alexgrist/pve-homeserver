
locals {
  admin_public_key = trimspace(
    file("${path.root}/keys/admin.pub")
  )

  # parse container yml definitions
  containers = {
    for filepath in fileset("${path.module}/containers", "*.yaml") :
    trimsuffix(filepath, ".yaml") => merge(
      # base structure
      {
        id         = null
        tags       = []
        extra_tags = []
        template   = null
        distro     = null
        resources  = null
        disk       = null
        network    = {}
        mounts     = []
      },

      yamldecode(file("${path.module}/containers/${filepath}")),
    )
  }
}

module "lxc" {
  for_each = local.containers
  source   = "../../modules/lxc-container"

  pve = {
    node      = var.pve_node
    datastore = var.pve_datastore
  }

  ssh_key    = local.admin_public_key
  hostname   = each.key
  id         = each.value.id
  tags       = each.value.tags
  template   = each.value.template
  distro     = each.value.distro
  resources  = each.value.resources
  disk       = each.value.disk
  network    = each.value.network
  mounts     = each.value.mounts
  extra_tags = each.value.extra_tags
}
