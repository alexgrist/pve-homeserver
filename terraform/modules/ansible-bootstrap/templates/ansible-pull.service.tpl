[Unit]
Description=Ansible pull from Git

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull -U ${git_repo_url} -i "localhost," ansible/local.yml --vault-password-file /etc/ansible/vault-pass
