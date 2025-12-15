# CoinNode

Sample Bitcoin Node Deployment

- Containerized Bitcoin Core 29.0 node
- Wrap in Helm to deploy to K8S
- CICD in GHA
- Log analisis with shell script and python

## AI Disclosure

This codebase was developed with the assistance of AI tooling, primarily Claude Code (Opus 4.5). All prompts and context inputs were authored by me.

AI assistance was used as a development aid — similar to tools such as linters, calculators, or IDE autocomplete — to help reason, iterate, and generate code suggestions. AI outputs were guided by carefully structured inputs and reviewed in full; nothing was accepted without human oversight.

I am fully responsible for the design, correctness, and maintenance of this codebase, and I can explain and modify any part of it as if it had been written entirely by hand.

# Pre-commit

A standard set of pre-commit hooks has been added to the repository to catch common issues before changes leave a developer’s machine. These checks enforce basic formatting and validation, perform static analysis on Terraform and Docker files, and scan for common security issues such as accidentally committed secrets. The goal is to shift feedback as far left as possible, reducing avoidable CI failures and preventing sensitive data from ever reaching source control.

## Installing pre-commit

This repository uses pre-commit to run local checks before changes are committed.

The recommended way to install pre-commit is via uv, which provides fast, isolated Python tool installs without relying on a system-wide Python environment.

Install pre-commit:

```sh
uv tool install pre-commit
```

Once installed, enable the hooks for this repository:

```sh
pre-commit install
```

The hooks will now run automatically on git commit. You can also run them manually against all files:

```sh
pre-commit run --all-files
```

If uv is not available, pre-commit can also be installed using other Python package managers, but uv is preferred for speed and reproducibility.

# Docker

In the Dockerfile I chose Red Hat’s Universal Base Image (UBI) as the runtime base. UBI provides a well-understood, enterprise-grade baseline with predictable patching and long-term support, while still allowing me to keep the image minimal. This strikes a balance between security, operational familiarity, and maintainability. UBI is commonly used in regulated and corporate environments, which makes it a defensible choice for production infrastructure.

For supply-chain security, I chose to vendor and store the trusted GPG public keys of the Bitcoin Core maintainers and verify the release signatures during the image build. This introduces a small maintenance cost when keys rotate, but it significantly strengthens the trust model compared to downloading and trusting a remote checksum alone. If an attacker were able to compromise the download endpoint or replace both the binary and the checksum, signature verification against pre-trusted keys would still prevent a successful build. This follows the standard Bitcoin Core release verification process and provides a clear, auditable chain of trust.

The image is built using a multi-stage Docker build. The first stages contain the tooling required to download, verify, and unpack the Bitcoin Core release, while the final runtime image contains only the verified binaries and the minimal runtime dependencies. This reduces the final image size, lowers the attack surface, and avoids shipping unnecessary build or verification tools into production.

The runtime container is configured to run as a non-root user with a dedicated UID and GID, and no shell access, following the principle of least privilege. Blockchain data is stored on a mounted volume so that node restarts or rescheduling do not result in data loss.

A container health check is included to verify that the node is responsive via bitcoin-cli using local RPC access. This checks real application health rather than just process existence, and allows the orchestrator to distinguish between a running but unhealthy node and a healthy one. The health check is intentionally lightweight and does not depend on full chain synchronisation, ensuring that startup and recovery are not unnecessarily delayed.

Overall, the Docker image prioritises supply-chain integrity, minimal runtime surface, and operational clarity, while remaining practical to build, debug, and maintain.

## Build and Run

Build the image:

```sh
docker build -t bitcoin-core:29.0 docker/
```

Run a quick sanity check in regtest mode (private, local-only network):

```sh
docker run --rm -e BITCOIN_NETWORK=regtest bitcoin-core:29.0
```
