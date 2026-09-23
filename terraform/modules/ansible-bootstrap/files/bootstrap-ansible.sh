#!/usr/bin/env bash
set -eu

ANSIBLE_USER="ansible"
ANSIBLE_HOME="/home/${ANSIBLE_USER}"
ANSIBLE_SSH_DIR="${ANSIBLE_HOME}/.ssh"
ANSIBLE_VAULT_FILE="${ANSIBLE_HOME}/.vault-pass"

export DEBIAN_FRONTEND=noninteractive

# install packages required for ansible and ansible-pull
apt-get update -qq
apt-get install -y sudo git ansible

# create the ansible user
if ! id -u "${ANSIBLE_USER}" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash ${ANSIBLE_USER}
fi

# install deploy ssh keys
install -d -m 0700 -o ${ANSIBLE_USER} -g ${ANSIBLE_USER} ${ANSIBLE_SSH_DIR}

if [[ -f /tmp/git_deploy_key ]]; then
    install -m 0600 -o "${ANSIBLE_USER}" -g "${ANSIBLE_USER}" \
    /tmp/git_deploy_key "${ANSIBLE_SSH_DIR}/id_rsa"
    shred -u /tmp/git_deploy_key 2>/dev/null || rm -f /tmp/git_deploy_key
fi

# setup ssh known hosts
ssh-keyscan -H github.com > "${ANSIBLE_SSH_DIR}/known_hosts" 2>/dev/null
chmod 0644 "${ANSIBLE_SSH_DIR}/known_hosts"
chown "${ANSIBLE_USER}:${ANSIBLE_USER}" "${ANSIBLE_SSH_DIR}/known_hosts"

# setup passwordless sudo
mkdir -p /etc/sudoers.d
chmod 0750 /etc/sudoers.d

cat > /etc/sudoers.d/ansible <<EOF
${ANSIBLE_USER} ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/ansible

# ansible vault password
if [[ -f /tmp/ansible_vault_pass ]]; then
    install -m 0600 -o "${ANSIBLE_USER}" -g "${ANSIBLE_USER}" \
    /tmp/ansible_vault_pass "${ANSIBLE_VAULT_FILE}"
    shred -u /tmp/ansible_vault_pass 2>/dev/null || rm -f /tmp/ansible_vault_pass
fi

# systemd service
install -m 0644 /tmp/ansible-pull.service /etc/systemd/system/ansible-pull.service
install -m 0644 /tmp/ansible-pull.timer   /etc/systemd/system/ansible-pull.timer
rm -f /tmp/ansible-pull.service /tmp/ansible-pull.timer

# enable and start the ansible-pull service
systemctl daemon-reload
systemctl enable ansible-pull.timer
systemctl restart ansible-pull.timer
systemctl start ansible-pull.service
