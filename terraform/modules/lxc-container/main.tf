
resource "terraform_data" "tags_version" {
  input = sort(var.tags)
}

locals {
  # PVE 9.2 supports per-mount-point UID/GID mappings (idmap), but the
  # provider does not expose them yet, so they are applied through the API.
  idmap_mounts = [
    for index, mount in var.mounts : {
      index = index
      idmap = mount.idmap
    } if try(mount.idmap, null) != null && mount.idmap != ""
  ]
}

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
    # recreate the container if the tags change, since they are used for playbook targeting
    # prevents containers from keeping stale configurations
    replace_triggered_by = [terraform_data.tags_version]

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

# PVE 9.2 per-mount-point idmap is not modelled by the provider yet, so it is
# written directly through the Proxmox API. Credentials are read from the same
# environment variables the provider uses, so no secret is stored in state.
resource "terraform_data" "mount_idmap" {
  count = length(local.idmap_mounts) > 0 ? 1 : 0

  # Re-run when the idmap values change, and whenever the container itself is
  # replaced (a fresh container starts without any mount point idmap).
  triggers_replace = [
    sha256(jsonencode(local.idmap_mounts)),
  ]

  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_container.this,
    ]
  }

  depends_on = [proxmox_virtual_environment_container.this]

  provisioner "local-exec" {
    environment = {
      NODE   = var.pve.node
      VMID   = proxmox_virtual_environment_container.this.vm_id
      IDMAPS = jsonencode(local.idmap_mounts)
    }

    command = <<-EOT
      set -euo pipefail

      if [ -z "$${PROXMOX_VE_API_TOKEN:-}" ] || [ -z "$${PROXMOX_VE_ENDPOINT:-}" ]; then
        echo "PROXMOX_VE_API_TOKEN and PROXMOX_VE_ENDPOINT must be set to apply mount point idmaps" >&2
        exit 1
      fi

      BASE="$${PROXMOX_VE_ENDPOINT%/}/api2/json/nodes/$NODE/lxc/$VMID"
      AUTH="Authorization: PVEAPIToken=$${PROXMOX_VE_API_TOKEN}"

      # Only stop/start when an idmap actually differs, so unrelated container
      # updates that re-trigger this resource do not incur downtime.
      pending=$(echo "$IDMAPS" | jq -c '.[]' | while read -r row; do
        index=$(printf '%s' "$row" | jq -r '.index')
        idmap=$(printf '%s' "$row" | jq -r '.idmap')

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

      # An idmap only takes effect on the next start, so stop first.
      curl -sf -X POST "$BASE/status/stop" -H "$AUTH" >/dev/null || true

      for _ in $(seq 1 60); do
        state=$(curl -sf "$BASE/status/current" -H "$AUTH" | jq -r '.data.status')
        [ "$state" = "stopped" ] && break
        sleep 1
      done

      for index in $pending; do
        idmap=$(echo "$IDMAPS" | jq -r --argjson i "$index" '.[] | select(.index == $i) | .idmap')
        current=$(curl -sf "$BASE/config" -H "$AUTH" | jq -r --arg key "mp$index" '.data[$key]')
        base=$(printf '%s' "$current" | sed 's/,idmap=[^,]*//g')
        curl -sf -X PUT "$BASE/config" -H "$AUTH" \
          --data-urlencode "mp$index=$base,idmap=$idmap" >/dev/null
      done

      curl -sf -X POST "$BASE/status/start" -H "$AUTH" >/dev/null
    EOT
  }
}
