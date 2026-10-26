
resource "terraform_data" "tags_version" {
  count = var.protection ? 0 : 1

  input = sort(var.tags)
}

locals {
  # mount point idmap needs PVE 9.2 and is not modelled by the provider yet
  mount_idmap = [
    for index, mount in var.mounts :
    {
      index = index
      idmap = mount.idmap
    }
    if mount.idmap != null
  ]
}

resource "proxmox_virtual_environment_container" "this" {
  description = var.description
  tags        = var.tags

  # pve protection prevents the container and its data volumes from being
  # destroyed by terraform and stray pct calls
  protection = var.protection

  node_name = var.pve.node
  vm_id     = var.id

  started       = var.started
  start_on_boot = var.start_on_boot

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

    user_account {
      keys = [var.ssh_key]
    }
  }

  disk {
    datastore_id = coalesce(try(var.disk.datastore, null), var.pve.datastore)
    size         = try(var.disk.size, 8)
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

  dynamic "mount_point" {
    for_each = var.mounts

    content {
      volume        = mount_point.value.volume
      path          = mount_point.value.path
      size          = mount_point.value.size
      backup        = mount_point.value.backup
      read_only     = mount_point.value.read_only
      acl           = mount_point.value.acl
      quota         = mount_point.value.quota
      replicate     = mount_point.value.replicate
      shared        = mount_point.value.shared
      mount_options = mount_point.value.mount_options
    }
  }

  lifecycle {
    # tags drive ansible role targeting, so a role change recreates the
    # container instead of updating stale tags on a provisioned filesystem;
    # protected containers keep their mounts and update tags in place
    replace_triggered_by = [terraform_data.tags_version]

    precondition {
      condition     = !var.data_tier || var.id != null
      error_message = "A data tier container must pin its ID; PVE volume names encode it."
    }

    precondition {
      condition     = !var.data_tier || (!var.started && !var.start_on_boot)
      error_message = "A data tier container must not start, keeping its volumes unmounted for the consumers."
    }

    precondition {
      condition     = !var.data_tier || var.protection
      error_message = "A data tier container must be protected; releasing the protection is a deliberate change."
    }
  }
}

# mount point idmap is not exposed by the provider, so it is reconciled through
# the API using the same credentials the provider reads from the environment
resource "terraform_data" "mount_idmap" {
  # the reconciler restarts the container, so it never runs on a container
  # that must stay stopped, like a data tier owner
  count = var.started && length(local.mount_idmap) > 0 ? 1 : 0

  triggers_replace = [
    sha256(jsonencode(local.mount_idmap)),
  ]

  lifecycle {
    # replaced containers start without any mount point idmap
    replace_triggered_by = [
      proxmox_virtual_environment_container.this,
    ]
  }

  depends_on = [proxmox_virtual_environment_container.this]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      NODE   = var.pve.node
      VMID   = proxmox_virtual_environment_container.this.vm_id
      MOUNTS = jsonencode(local.mount_idmap)
    }

    command = <<-EOT
      set -euo pipefail

      if [ -z "$${PROXMOX_VE_API_TOKEN:-}" ] || [ -z "$${PROXMOX_VE_ENDPOINT:-}" ]; then
        echo "PROXMOX_VE_API_TOKEN and PROXMOX_VE_ENDPOINT must be set to apply mount point idmaps" >&2
        exit 1
      fi

      BASE="$${PROXMOX_VE_ENDPOINT%/}/api2/json/nodes/$NODE/lxc/$VMID"
      AUTH="Authorization: PVEAPIToken=$${PROXMOX_VE_API_TOKEN}"

      # only reconcile mounts whose idmap differs from the container config
      pending=$(echo "$MOUNTS" | jq -c '.[]' | while read -r row; do
        index=$(printf '%s' "$row" | jq -r '.index')
        idmap=$(printf '%s' "$row" | jq -r '.idmap // empty')

        current=$(curl -sf "$BASE/config" -H "$AUTH" | jq -r --arg key "mp$index" '.data[$key]')
        if [ -z "$current" ] || [ "$current" = "null" ]; then
          echo "mount point mp$index not found on container $VMID" >&2
          exit 1
        fi

        existing=$(printf '%s' "$current" | sed -n 's/.*,idmap=\([^,]*\).*/\1/p')
        [ "$existing" = "$idmap" ] || echo "$index"
      done | sort -u)

      if [ -z "$pending" ]; then
        echo "mount point idmap already up to date on container $VMID"
        exit 0
      fi

      # an idmap only takes effect on the next start, so stop first and always
      # restart afterwards, even if a later step fails
      trap 'curl -sf -X POST "$BASE/status/start" -H "$AUTH" >/dev/null || true' EXIT

      curl -sf -X POST "$BASE/status/stop" -H "$AUTH" >/dev/null || true

      for _ in $(seq 1 60); do
        state=$(curl -sf "$BASE/status/current" -H "$AUTH" | jq -r '.data.status')
        [ "$state" = "stopped" ] && break
        sleep 1
      done

      if [ "$state" != "stopped" ]; then
        echo "container $VMID did not stop within 60 seconds" >&2
        exit 1
      fi

      for index in $pending; do
        idmap=$(echo "$MOUNTS" | jq -r --argjson i "$index" '.[] | select(.index == $i) | .idmap // empty')
        current=$(curl -sf "$BASE/config" -H "$AUTH" | jq -r --arg key "mp$index" '.data[$key]')
        base=$(printf '%s' "$current" | sed -e 's/,idmap=[^,]*//g' -e 's/^idmap=[^,]*,//g' -e 's/^idmap=[^,]*$//g')

        # an empty idmap removes the mapping, a non-empty one replaces it
        if [ -n "$idmap" ]; then
          curl -sf -X PUT "$BASE/config" -H "$AUTH" \
            --data-urlencode "mp$index=$base,idmap=$idmap" >/dev/null
        else
          curl -sf -X PUT "$BASE/config" -H "$AUTH" \
            --data-urlencode "mp$index=$base" >/dev/null
        fi
      done
    EOT
  }
}
