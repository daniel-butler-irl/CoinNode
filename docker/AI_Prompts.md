# Prompts

> **Note**: This file documents the initial AI planning prompts. The implementation has since evolved:
> - Data directory changed from `/home/bitcoin/.bitcoin` to `/var/lib/bitcoin`
> - Config file location changed to `/etc/bitcoin/bitcoin.conf` (separate from data)

> in the docker directory create a docker file to containerize Bitcoin Core 29.0 node from official source. base it on a ubi minial image with security and reliablity in mind, such as running as non root user. Include an entry point to start the node and output the logs to stdout/stderr.

**AI PLAN**
 Bitcoin Core 29.0 Docker Implementation Plan

 Overview

 Create a secure, production-ready Dockerfile for Bitcoin Core 29.0 using UBI
 minimal base image with security hardening and proper log handling.

 Files to Create

 1. docker/Dockerfile

 Multi-stage build with 3 stages:

 Stage 1 (verifier): Download and verify Bitcoin Core
 - Base: registry.access.redhat.com/ubi9/ubi-minimal
 - Install: gnupg2, tar, gzip, ca-certificates, curl
 - Download from https://bitcoincore.org/bin/bitcoin-core-29.0/:
   - bitcoin-29.0-x86_64-linux-gnu.tar.gz
   - SHA256SUMS and SHA256SUMS.asc
 - Import trusted builder GPG keys and verify signatures
 - Verify SHA256 checksum

 Stage 2 (preparer): Extract and organize binaries
 - Extract bitcoind and bitcoin-cli only
 - Set up /opt/bitcoin/bin/ structure

 Stage 3 (runtime): Minimal production image
 - Base: registry.access.redhat.com/ubi9/ubi-minimal
 - Create non-root user bitcoin (UID/GID 1000)
 - Copy binaries and entrypoint
 - Set environment variables and expose ports

 2. docker/entrypoint.sh

 Bash script with:
 - Signal handling (SIGTERM/SIGINT) for graceful shutdown
 - Network selection via BITCOIN_NETWORK env var (mainnet/testnet/regtest/signet)
 - -printtoconsole flag for stdout/stderr logging
 - Graceful shutdown using bitcoin-cli stop

 3. docker/builder-keys/ directory

 GPG public keys from trusted Bitcoin Core maintainers:
 - achow101.gpg (Andrew Chow - release manager)
 - fanquake.gpg (Michael Ford)
 - laanwj.gpg (Wladimir van der Laan)

 Security Features

 - GPG signature verification of binaries
 - SHA256 checksum verification
 - Non-root user execution
 - Multi-stage build (no build tools in final image)
 - Minimal UBI base image
 - No shell access for bitcoin user (/sbin/nologin)

 Configuration

 Environment Variables:
 | Variable        | Default                | Description    |
 |-----------------|------------------------|----------------|
 | BITCOIN_NETWORK | mainnet                | Network mode   |
 | BITCOIN_DATA    | /home/bitcoin/.bitcoin | Data directory |

 Exposed Ports:
 - Mainnet: 8332 (RPC), 8333 (P2P)
 - Testnet: 18332, 18333
 - Regtest: 18443, 18444
 - Signet: 38332, 38333

 Volume:
 - /home/bitcoin/.bitcoin - Blockchain data persistence

 4. docker/.dockerignore

 Exclude unnecessary files from build context:
 - *.md (except needed docs)
 - .git
 - *.log

 5. Health Check (in Dockerfile)

 HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
     CMD bitcoin-cli -datadir=${BITCOIN_DATA} getblockchaininfo || exit 1

 Usage Examples

 # Build
 docker build -t bitcoin-core:29.0 docker/

 # Run mainnet
 docker run -d -v bitcoin-data:/home/bitcoin/.bitcoin \
   -p 8333:8333 bitcoin-core:29.0

 # Run testnet
 docker run -d -e BITCOIN_NETWORK=testnet \
   -v bitcoin-testnet:/home/bitcoin/.bitcoin \
   -p 18333:18333 bitcoin-core:29.0

 # Graceful stop (allow time for mempool flush)
 docker stop -t 120 <container>
