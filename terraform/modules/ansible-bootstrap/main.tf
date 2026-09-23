
resource "terraform_data" "ansible_bootstrap" {
  triggers_replace = [
    var.container_id
  ]

  connection {
    type        = "ssh"
    host        = var.container_ip
    user        = "root"
    private_key = var.ssh_private_key
  }

  # private key used for ansible-pull to clone the git repo
  provisioner "file" {
    content     = var.git_deploy_private_key
    destination = "/tmp/git_deploy_key"
  }

  # ansible vault password used to encrypt/decrypt secrets
  provisioner "file" {
    content     = var.vault_password
    destination = "/tmp/ansible_vault_pass"
  }

  # service unit file for ansible-pull
  provisioner "file" {
    content = templatefile("${path.module}/templates/ansible-pull.service.tpl", {
      git_repo_url = var.git_repo_url
    })
    destination = "/tmp/ansible-pull.service"
  }

  # timer unit file for ansible-pull
  provisioner "file" {
    content     = file("${path.module}/templates/ansible-pull.timer")
    destination = "/tmp/ansible-pull.timer"
  }

  # bootstrap script to install ansible and configure ansible-pull service
  provisioner "file" {
    content     = file("${path.module}/files/bootstrap-ansible.sh")
    destination = "/tmp/bootstrap-ansible.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0700 /tmp/bootstrap-ansible.sh",
      "sed -i 's/\\r$//' /tmp/bootstrap-ansible.sh",
      "/bin/bash /tmp/bootstrap-ansible.sh",
      "rm -f /tmp/bootstrap-ansible.sh",
    ]
  }
}
