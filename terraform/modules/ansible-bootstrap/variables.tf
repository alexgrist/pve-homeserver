
variable "container_id" {
  description = "The ID of the container"
  type        = string
}

variable "container_ip" {
  description = "The IP address of the container"
  type        = string
}

variable "ssh_private_key" {
  description = "The SSH key used to bootstrap the container"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "git_deploy_private_key" {
  description = "The SSH key used to deploy the Ansible project from Git"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "git_repo_url" {
  description = "The URL of the Git repository containing the Ansible project"
  type        = string
}

variable "vault_password" {
  description = "The Ansible vault password"
  type        = string
  sensitive   = true
  ephemeral   = true
}
