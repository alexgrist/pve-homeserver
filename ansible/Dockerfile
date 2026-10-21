FROM debian:trixie

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV PATH="/opt/ansible-env/bin:$PATH" \
    ANSIBLE_CONFIG=/etc/ansible/ansible.cfg \
    ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_RETRY_FILES_ENABLED=False \
    ANSIBLE_DEPRECATION_WARNINGS=False

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
    python3 \
    git \
    ca-certificates \
    openssh-client \
    sshpass && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    apt-get clean

COPY requirements.yml /tmp/requirements.yml

RUN uv venv /opt/ansible-env && \
    uv pip install --no-cache \
    cffi \
    ansible-core \
    ansible-lint \
    proxmoxer \
    paramiko \
    requests

RUN /opt/ansible-env/bin/ansible-galaxy install -r /tmp/requirements.yml -p /usr/share/ansible/roles && \
    /opt/ansible-env/bin/ansible-galaxy collection install -r /tmp/requirements.yml && \
    rm /tmp/requirements.yml

RUN mkdir -p /workspace && \
    chmod 700 /workspace

WORKDIR /workspace

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD [ "ansible", "--version" ]

CMD ["ansible-playbook", "--version"]
