[Unit]
Description=Ansible pull from Git
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=root

StateDirectory=ansible-pull
StateDirectoryMode=0755
CacheDirectory=ansible-pull
CacheDirectoryMode=0755

Environment=ANSIBLE_NOCOLOR=1
Environment=ANSIBLE_CONFIG=%S/ansible-pull/ansible/ansible.cfg
Environment=ANSIBLE_LOCAL_TEMP=%C/ansible-pull/tmp
Environment=ANSIBLE_REMOTE_TEMP=%C/ansible-pull/tmp

ExecStart=/usr/bin/ansible-pull \
	--private-key /root/.ssh/id_rsa \
	--accept-host-key \
	--url ${git_repo_url} \
	--directory %S/ansible-pull \
	--inventory "localhost," \
	--limit "localhost" \
	--vault-password-file /etc/ansible/.vault-pass \
	--clean --purge --only-if-changed \
	%S/ansible-pull/ansible/local.yml

NoNewPrivileges=true
ProtectHome=read-only
ReadWritePaths=/etc/ansible
PrivateTmp=true

[Install]
WantedBy=multi-user.target
