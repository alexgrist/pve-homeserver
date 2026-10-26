locals {
  # parse container yml definitions
  containers = {
    for filepath in fileset(var.containers_dir, "*.yaml") :
    trimsuffix(filepath, ".yaml") => merge(
      # base structure
      {
        id            = null
        tags          = []
        extra_tags    = []
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

      yamldecode(file("${var.containers_dir}/${filepath}")),
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
          volume = coalesce(lookup(mount, "storage", null), var.pve.datastore)
          size   = lookup(mount, "size", null)
          backup = lookup(mount, "backup", true)
        }
      }
    ]
  ])...)
}

module "data_tier" {
  source   = "../lxc-container"
  for_each = local.data_tier

  pve     = var.pve
  ssh_key = var.ssh_key

  hostname      = each.key
  id            = each.value.id
  tags          = each.value.tags
  extra_tags    = each.value.extra_tags
  template      = each.value.template
  distro        = each.value.distro
  resources     = each.value.resources
  disk          = each.value.disk
  network       = each.value.network
  protection    = each.value.protection
  started       = each.value.started
  start_on_boot = each.value.start_on_boot
  data_tier     = each.value.data_tier

  # volumes owned by this tier are declared by the containers that mount
  # them, with the owner key stripped before the module call
  mounts = [
    for path, mount in local.storage_mounts : merge(
      { path = path },
      { for key, value in mount : key => value if key != "owner" },
    ) if mount.owner == each.key
  ]
}

module "lxc" {
  source   = "../lxc-container"
  for_each = { for key, container in local.containers : key => container if !container.data_tier }

  pve     = var.pve
  ssh_key = var.ssh_key

  hostname      = each.key
  id            = each.value.id
  tags          = each.value.tags
  extra_tags    = each.value.extra_tags
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
