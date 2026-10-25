
locals {
  deploy_public_key = trimspace(
    file("${path.root}/keys/deploy.pub")
  )

  # parse container yml definitions
  containers = {
    for filepath in fileset("${path.module}/containers", "*.yaml") :
    trimsuffix(filepath, ".yaml") => merge(
      # base structure
      {
        id            = null
        tags          = []
        template      = null
        distro        = null
        resources     = null
        disk          = null
        network       = {}
        mounts        = []
        protection    = false
        started       = true
        start_on_boot = true
        data_tier     = false
      },

      yamldecode(file("${path.module}/containers/${filepath}")),
    )
  }

  # data tier containers own the volumes other containers mount
  data_tier = { for key, container in local.containers : key => container if container.data_tier }

  # mount points routed to a storage tier container, keyed by the mount path
  # they will have on the tier. size, storage and backup configure the
  # volume itself; every other mount attribute stays an attach option
  storage_mounts = merge(flatten([
    for key, container in local.containers : [
      for mount in container.mounts : lookup(mount, "owner", null) == null ? {} : {
        "/data/${key}${mount.path}" = {
          owner  = mount.owner
          volume = coalesce(lookup(mount, "storage", null), var.pve_datastore)
          size   = lookup(mount, "size", null)
          backup = lookup(mount, "backup", true)
        }
      }
    ]
  ])...)
}

module "data_tier" {
  source   = "../../modules/lxc-container"
  for_each = local.data_tier

  pve = {
    node      = var.pve_node
    datastore = var.pve_datastore
  }

  ssh_key   = local.deploy_public_key
  hostname  = each.key
  id        = each.value.id
  tags      = each.value.tags
  template  = each.value.template
  distro    = each.value.distro
  resources = each.value.resources
  disk      = each.value.disk
  network   = each.value.network
  # volumes owned by this tier are declared by the containers that mount
  # them, with the owner key stripped before the module call
  mounts = [
    for path, mount in local.storage_mounts : merge(
      { path = path },
      { for key, value in mount : key => value if key != "owner" },
    ) if mount.owner == each.key
  ]
  protection    = each.value.protection
  started       = each.value.started
  start_on_boot = each.value.start_on_boot
  data_tier     = each.value.data_tier
}

module "lxc" {
  source   = "../../modules/lxc-container"
  for_each = { for key, container in local.containers : key => container if !container.data_tier }

  pve = {
    node      = var.pve_node
    datastore = var.pve_datastore
  }

  ssh_key       = local.deploy_public_key
  hostname      = each.key
  id            = each.value.id
  tags          = each.value.tags
  template      = each.value.template
  distro        = each.value.distro
  resources     = each.value.resources
  disk          = each.value.disk
  network       = each.value.network
  protection    = each.value.protection
  started       = each.value.started
  start_on_boot = each.value.start_on_boot

  # mounts with an owner resolve to the storage volume declared for them;
  # size, storage and backup are tier options, the rest are attach options
  mounts = [
    for mount in each.value.mounts : merge(
      { for key, value in mount : key => value if !contains(["owner", "storage", "backup", "size"], key) },
      lookup(mount, "owner", null) != null ? {
        volume = module.data_tier[mount.owner].volumes["/data/${each.key}${mount.path}"]
        } : {
        size = lookup(mount, "size", null)
      },
    )
  ]
}
