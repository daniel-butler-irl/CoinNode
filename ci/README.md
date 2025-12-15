# CI/CD Pipeline

> **Note**: GitHub Actions requires workflow files to be in `.github/workflows/`. See [.github/workflows/](../.github/workflows/) for pipeline configuration.

## Version Pinning

Workflows referenced with full repository path and version:

```yaml
uses: daniel-butler-irl/CoinNode/.github/workflows/build.yml@v1.0.0
```

## Pipeline Stages

```text
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Pre-commit  │────▶│   Build     │────▶│  Release    │
│             │     │ Scan & Push │     │  (tags)     │
└─────────────┘     └─────────────┘     └─────────────┘
```

| Stage | Trigger | Description |
|-------|---------|-------------|
| Pre-commit | All pushes/PRs | Run pre-commit hooks |
| Build | main + tags | Build, scan (Trivy), push to GHCR |
| Release | v*.*.* tags | Create GitHub release |

## Vulnerability Scan Policy

| Setting | Value |
|---------|-------|
| Scanner | Trivy @0.29.0 |
| Threshold | `CRITICAL,HIGH` |
| Behavior | Pipeline fails on detection |
| Results | GitHub Security tab (SARIF) |

## Container Image

```bash
docker pull ghcr.io/daniel-butler-irl/coinnode:latest
gh attestation verify oci://ghcr.io/daniel-butler-irl/coinnode:latest --owner daniel-butler-irl
```
