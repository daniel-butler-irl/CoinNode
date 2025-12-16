# CoinNode

Containerized Bitcoin Core 29.0 node with Kubernetes orchestration, CI/CD pipeline, and operational tooling.

## AI Disclosure

This codebase was developed with the assistance of AI tooling, primarily Claude Code (Opus 4.5). All prompts and context inputs were authored by me.

AI assistance was used as a development aid — similar to tools such as linters, calculators, or IDE autocomplete — to help reason, iterate, and generate code suggestions. AI outputs were guided by carefully structured inputs and reviewed in full; nothing was accepted without human oversight.

I am fully responsible for the design, correctness, and maintenance of this codebase, and I can explain and modify any part of it as if it had been written entirely by hand.

My AI workflow is to work with the AI in Plan mode to define the problem and high level solution. Generate a base with that plan. Then manually review, and refactor as needed. The AI_Prompts.md files show initial plans that often evolved during implementation — comparing these plans to the final code demonstrates active human decision-making rather than passive acceptance.

Each directory contains an `AI_Prompts.md` file with the initial planning prompts and AI-generated plans. Not every prompt was recorded, just as not every change from code formatters was recorded — these files capture the key planning discussions that shaped each component.

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 20.10+ | Build and run container |
| kubectl | 1.28+ | Kubernetes deployment |
| Kubernetes cluster | 1.28+ | minikube, kind, or remote cluster |
| uv | 0.4+ | Python package manager |
| Terraform | >= 1.5 | IAM module |
| Go | >= 1.21 | Terraform tests (optional) |
| AWS credentials | - | Terraform apply |

## Build and Scan

Build the container image:

```sh
docker build -t bitcoin-core:29.0 docker/
```

Run locally in regtest mode:

```sh
docker run --rm -e BITCOIN_NETWORK=regtest bitcoin-core:29.0
```

Verify non-root execution:

```sh
docker run --rm --entrypoint id bitcoin-core:29.0
# Output: uid=1000(bitcoin) gid=1000(bitcoin) groups=1000(bitcoin)
```

Pull and verify pre-built image attestation:

```sh
docker pull ghcr.io/daniel-butler-irl/coinnode:latest
gh attestation verify oci://ghcr.io/daniel-butler-irl/coinnode:latest --owner daniel-butler-irl
```

Security scanning uses Trivy with threshold: **CRITICAL, HIGH** (pipeline fails on detection).

## Deploy to Kubernetes

Deploy all manifests:

```sh
kubectl apply -f orchestration/
```

Verify deployment:

```sh
kubectl rollout status deployment/bitcoin-node --timeout=300s
kubectl get pods -l app=bitcoin-node
kubectl logs -l app=bitcoin-node
```

Test RPC connectivity:

```sh
kubectl exec -it deploy/bitcoin-node -- bitcoin-cli -regtest -datadir=/var/lib/bitcoin -conf=/etc/bitcoin/bitcoin.conf getblockchaininfo
```

## Log Analysis Tools

### Shell Script

```sh
# From file
./scripts/shell/log-ip-freq.sh scripts/sample.log

# From stdin
cat scripts/sample.log | ./scripts/shell/log-ip-freq.sh
```

### Python CLI

`uv run` automatically creates a virtual environment and installs dependencies on first use.

```sh
cd scripts/python

# From file
uv run log-ip-freq --file ../sample.log

# From stdin
cat ../sample.log | uv run log-ip-freq

# Run tests
uv run pytest -v
```

Output format (both tools):

```
count ip_address
```

## Terraform IAM Module

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Run Terratest:

```sh
cd terraform/test
go test -v -timeout 30m
```

See [terraform/README.md](terraform/README.md) for detailed inputs and outputs.

## Assumptions and Limitations

- **Network mode**: Configured for regtest (private local network), not mainnet
- **Storage**: 1Gi PVC suitable for regtest; mainnet requires 500Gi+
- **Data directory**: `/var/lib/bitcoin` (data), `/etc/bitcoin/bitcoin.conf` (config)
- **Storage class**: PVC uses cluster default (set explicitly for production)
- **RPC credentials**: Placeholder values in secret.yaml; replace for production
- **CI/CD location**: Workflows are in `.github/workflows/` (required by GitHub Actions) rather than `/ci/`; the `/ci/` directory contains documentation only
- **Nomad orchestration**: Not implemented (Kubernetes path chosen)

## Project Structure

```
/docker/         Dockerfile and build assets
/orchestration/  Kubernetes manifests
/ci/             Pipeline documentation
/scripts/        Log analysis tools (shell + Python)
/terraform/      IAM module
```

Each directory contains a README with detailed design rationale.

## Development Setup

### Pre-commit Hooks

Pre-commit hooks enforce formatting, validation, static analysis, and secret detection before commits reach CI.

```sh
# Install pre-commit
uv tool install pre-commit

# Enable hooks for this repository
pre-commit install

# Run manually against all files
pre-commit run --all-files
```

## References

- [Bitcoin Core](https://github.com/bitcoin/bitcoin)
- [Red Hat UBI Images](https://catalog.redhat.com/en/software/containers/ubi9-minimal/61832888c0d15aff4912fe0d)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
