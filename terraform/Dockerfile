FROM ghcr.io/opentofu/opentofu:minimal AS tofu

FROM debian:trixie

COPY --from=tofu /usr/local/bin/tofu /usr/local/bin/tofu

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    jq && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    apt-get clean

WORKDIR /workspace

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD [ "tofu", "--version" ]

CMD ["tofu", "--version"]
