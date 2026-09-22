
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

  provisioner "file" {
    content     = var.git_deploy_private_key
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /root/.ssh/id_rsa",
      "ssh-keyscan -H github.com > /root/.ssh/known_hosts",
      "chmod 0644 /root/.ssh/known_hosts",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y git ansible",
      "mkdir -p /etc/ansible",
    ]
  }

  provisioner "file" {
    content     = var.vault_password
    destination = "/etc/ansible/vault-pass"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/ansible-pull.service.tpl", {
      git_repo_url = var.git_repo_url
    })
    destination = "/etc/systemd/system/ansible-pull.service"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/ansible-pull.timer")
    destination = "/etc/systemd/system/ansible-pull.timer"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /etc/ansible/vault-pass",
      "systemctl daemon-reload",
      "systemctl enable ansible-pull.timer",
      "systemctl start ansible-pull.timer",
      "systemctl start ansible-pull.service"
    ]
  }
}
