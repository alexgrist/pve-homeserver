output "containers" {
  description = "The ID and IP of every container, keyed by hostname"
  value = merge(
    { for hostname, container in module.lxc : hostname => { id = container.container_id, ip = container.container_ip } },
    { for hostname, container in module.data_tier : hostname => { id = container.container_id, ip = null } },
  )
}
