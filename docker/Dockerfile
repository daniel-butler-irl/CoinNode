# =============================================================================
# Bitcoin Core 29.0 - Secure Container Image
# Base: Red Hat UBI 9 Minimal (pinned digest for reproducibility)
# =============================================================================

# =============================================================================
# Base Image Configuration
# Pin to specific digest for reproducible builds and supply chain security
# Update digest periodically via: skopeo inspect docker://registry.access.redhat.com/ubi9/ubi-minimal
# =============================================================================
ARG UBI_IMAGE=registry.access.redhat.com/ubi9/ubi-minimal
ARG UBI_DIGEST=sha256:dfc52e9c80bc87a69153bbb5684a2ea8f0ebf280ff28f0ded8ba9c9ceff19203

# =============================================================================
# Stage 1: Download and Verify Bitcoin Core
# =============================================================================
FROM ${UBI_IMAGE}@${UBI_DIGEST} AS verifier

ARG BITCOIN_VERSION=29.0
ARG TARGETARCH

# Install verification tools
# Note: curl-minimal is pre-installed in UBI minimal, so we don't need to install curl
# hadolint ignore=DL3041
RUN microdnf install -y \
        gnupg2 \
        tar \
        gzip \
        coreutils-single \
        ca-certificates \
    && microdnf clean all \
    && rm -rf /var/cache/yum

WORKDIR /tmp/bitcoin

# Copy trusted builder GPG keys
COPY builder-keys/*.gpg /tmp/builder-keys/

# Import trusted builder keys
RUN gpg --batch --import /tmp/builder-keys/*.gpg

# Download and verify Bitcoin Core
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
    if [ -n "${TARGETARCH:-}" ]; then \
      case "${TARGETARCH}" in \
        amd64|x86_64) BITCOIN_ARCH="x86_64" ;; \
        arm64|aarch64) BITCOIN_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
      esac; \
    else \
      case "$(uname -m)" in \
        x86_64|amd64) BITCOIN_ARCH="x86_64" ;; \
        aarch64|arm64) BITCOIN_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture $(uname -m)" >&2; exit 1 ;; \
      esac; \
    fi; \
    ARCHIVE="bitcoin-${BITCOIN_VERSION}-${BITCOIN_ARCH}-linux-gnu.tar.gz"; \
    BASE_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}"; \
    curl -fsSL "${BASE_URL}/${ARCHIVE}" -o "${ARCHIVE}"; \
    curl -fsSL "${BASE_URL}/SHA256SUMS" -o SHA256SUMS; \
    curl -fsSL "${BASE_URL}/SHA256SUMS.asc" -o SHA256SUMS.asc; \
    # Verify GPG signatures - require at least one good signature from our trusted keys \
    GOOD_SIGS=$(gpg --batch --verify --status-fd 1 SHA256SUMS.asc SHA256SUMS 2>/dev/null | grep -c "GOODSIG" || true); \
    echo "Found ${GOOD_SIGS} valid signature(s) from trusted keys"; \
    if [ "${GOOD_SIGS}" -lt 1 ]; then \
      echo "ERROR: No valid signatures from trusted keys!" >&2; \
      exit 1; \
    fi; \
    # Verify SHA256 checksum \
    sha256sum --ignore-missing --check SHA256SUMS; \
    tar -xzf "${ARCHIVE}"; \
    mv "bitcoin-${BITCOIN_VERSION}" bitcoin

# =============================================================================
# Stage 2: Prepare Runtime Files
# =============================================================================
ARG UBI_IMAGE
ARG UBI_DIGEST
FROM ${UBI_IMAGE}@${UBI_DIGEST} AS preparer

COPY --from=verifier /tmp/bitcoin/bitcoin /tmp/bitcoin

# Create optimized directory structure with only required binaries
RUN mkdir -p /opt/bitcoin/bin && \
    cp /tmp/bitcoin/bin/bitcoind /opt/bitcoin/bin/ && \
    cp /tmp/bitcoin/bin/bitcoin-cli /opt/bitcoin/bin/ && \
    chmod 755 /opt/bitcoin/bin/*

# =============================================================================
# Stage 3: Final Runtime Image
# =============================================================================
ARG UBI_IMAGE
ARG UBI_DIGEST
FROM ${UBI_IMAGE}@${UBI_DIGEST} AS runtime

ARG BITCOIN_UID=1000
ARG BITCOIN_GID=1000

LABEL maintainer="CoinNode Project" \
      org.opencontainers.image.title="Bitcoin Core" \
      org.opencontainers.image.version="29.0" \
      org.opencontainers.image.description="Production-ready Bitcoin Core node on UBI minimal" \
      org.opencontainers.image.source="https://github.com/bitcoin/bitcoin" \
      org.opencontainers.image.licenses="MIT"

# Create bitcoin user without useradd (UBI minimal limitation)
# Using direct passwd/group file manipulation for minimal footprint
RUN echo "bitcoin:x:${BITCOIN_UID}:${BITCOIN_GID}:Bitcoin Daemon User:/home/bitcoin:/sbin/nologin" >> /etc/passwd && \
    echo "bitcoin:x:${BITCOIN_GID}:" >> /etc/group && \
    mkdir -p /home/bitcoin/.bitcoin && \
    chown -R ${BITCOIN_UID}:${BITCOIN_GID} /home/bitcoin

# Copy binaries from preparer stage
COPY --from=preparer --chown=root:root /opt/bitcoin/bin/ /opt/bitcoin/bin/
RUN chmod 755 /opt/bitcoin/bin/*

# Copy entrypoint script
COPY --chown=root:root entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Environment variables
ENV BITCOIN_DATA=/home/bitcoin/.bitcoin \
    BITCOIN_NETWORK=mainnet \
    PATH="/opt/bitcoin/bin:${PATH}"

# Switch to non-root user
USER bitcoin
WORKDIR /home/bitcoin

# Data volume for blockchain persistence
VOLUME ["/home/bitcoin/.bitcoin"]

# Expose ports for all networks
# Mainnet: P2P (8333), RPC (8332)
# Testnet: P2P (18333), RPC (18332)
# Regtest: P2P (18444), RPC (18443)
# Signet:  P2P (38333), RPC (38332)
EXPOSE 8332 8333 18332 18333 18443 18444 38332 38333

# Health check - verifies bitcoind is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /bin/sh -ec 'FLAG=""; case "${BITCOIN_NETWORK:-mainnet}" in testnet) FLAG="-testnet";; regtest) FLAG="-regtest";; signet) FLAG="-signet";; esac; bitcoin-cli -datadir="${BITCOIN_DATA:-/home/bitcoin/.bitcoin}" ${FLAG} getblockchaininfo >/dev/null'

ENTRYPOINT ["/entrypoint.sh"]
