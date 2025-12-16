# Docker

In the Dockerfile I chose Red Hat’s Universal Base Image (UBI) as the runtime base. UBI provides a well-understood, enterprise-grade baseline with predictable patching and long-term support, while still allowing me to keep the image minimal. This strikes a balance between security, operational familiarity, and maintainability. UBI is commonly used in regulated and corporate environments, which makes it a defensible choice for production infrastructure.

For supply-chain security, I chose to vendor and store the trusted GPG public keys of the Bitcoin Core maintainers and verify the release signatures during the image build. This introduces a small maintenance cost when keys rotate, but it significantly strengthens the trust model compared to downloading and trusting a remote checksum alone. If an attacker were able to compromise the download endpoint or replace both the binary and the checksum, signature verification against pre-trusted keys would still prevent a successful build. This follows the standard Bitcoin Core release verification process and provides a clear, auditable chain of trust.

The image is built using a multi-stage Docker build. The first stages contain the tooling required to download, verify, and unpack the Bitcoin Core release, while the final runtime image contains only the verified binaries and the minimal runtime dependencies. This reduces the final image size, lowers the attack surface, and avoids shipping unnecessary build or verification tools into production.

The runtime container is configured to run as a non-root user with a dedicated UID and GID, and no shell access, following the principle of least privilege. Blockchain data is stored on a mounted volume so that node restarts or rescheduling do not result in data loss.

A container health check is included to verify that the node is responsive via bitcoin-cli using local RPC access. This checks real application health rather than just process existence, and allows the orchestrator to distinguish between a running but unhealthy node and a healthy one. The health check is intentionally lightweight and does not depend on full chain synchronisation, ensuring that startup and recovery are not unnecessarily delayed.

Overall, the Docker image prioritises supply-chain integrity, minimal runtime surface, and operational clarity, while remaining practical to build, debug, and maintain.
