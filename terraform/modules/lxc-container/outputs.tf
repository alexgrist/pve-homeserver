output "container_id" {
  description = "The ID of the container"
  value       = proxmox_virtual_environment_container.this.id
}

output "container_ip" {
  description = "The IP address of the container"
  value       = one(values(proxmox_virtual_environment_container.this.ipv4))
}
