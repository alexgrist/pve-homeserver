output "container_id" {
  description = "The ID of the container"
  value       = proxmox_virtual_environment_container.this.id
}

output "volumes" {
  description = "The volume ID of each mount point, keyed by mount path"
  value       = { for mount_point in proxmox_virtual_environment_container.this.mount_point : mount_point.path => mount_point.volume }
}

output "container_ip" {
  description = "The IP address of the container"
  value       = one(values(proxmox_virtual_environment_container.this.ipv4))
}
