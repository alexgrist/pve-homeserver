output "containers" {
  description = "The ID and IP of every container, keyed by hostname"
  value       = module.containers.containers
}
