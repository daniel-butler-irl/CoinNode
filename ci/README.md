# CI/CD Pipeline

Reusable workflows stored here, symlinked to `.github/workflows/` for GitHub Actions.

## Structure

```text
ci/
├── pre-commit.yml      # Source: Pre-commit hooks
├── build.yml           # Source: Build, scan, push to GHCR
├── release.yml         # Source: Create GitHub release
└── README.md

.github/workflows/
├── ci.yml              # Main orchestrator
├── pre-commit.yml -> ../../ci/pre-commit.yml
├── build.yml -> ../../ci/build.yml
└── release.yml -> ../../ci/release.yml
```

## Version Pinning

Workflows are referenced with full repository path and version:

```yaml
uses: daniel-butler-irl/CoinNode/.github/workflows/build.yml@v1.0.0
```

To pin to a specific version, create a tag and update `ci.yml`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Then update references from `@main` to `@v1.0.0`.

## Pipeline Stages

```text
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Pre-commit  │────▶│   Build     │────▶│  Release    │
│             │     │ Scan & Push │     │  (tags)     │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Stage 1: Pre-commit

- Runs on **all pushes and PRs**
- Executes all pre-commit hooks defined in `.pre-commit-config.yaml`
- Catches issues developers may have skipped locally

### Stage 2: Build, Scan & Push

- Runs on **main branch and version tags**
- Multi-architecture build (amd64, arm64)
- Vulnerability scanning with Trivy (fails on CRITICAL/HIGH)
- Pushes to GitHub Container Registry (ghcr.io)
- Generates SLSA provenance attestation

### Stage 3: Release

- Runs only on **version tags** (`v*.*.*`)
- Creates GitHub release with auto-generated notes
- Includes container pull instructions

## Vulnerability Scan Policy

| Setting | Value |
|---------|-------|
| Scanner | [Trivy](https://github.com/aquasecurity/trivy) @0.29.0 |
| Threshold | `CRITICAL,HIGH` |
| Behavior | **Pipeline fails** on detection |
| Unfixed CVEs | Ignored |
| Results | GitHub Security tab (SARIF) |

## Security Features

- **Version-pinned workflows**: Full repo path + tag reference
- **First-party actions**: GitHub official actions with release pins
- **Minimal permissions**: Each job gets only required permissions
- **OIDC authentication**: Keyless auth to GHCR
- **Pinned base image**: Dockerfile uses digest-pinned UBI9
- **Supply chain attestations**: SLSA provenance

## Container Image Tags

| Tag Pattern | Example | Trigger |
|-------------|---------|---------|
| `latest` | `ghcr.io/daniel-butler-irl/coinnode:latest` | Push to main |
| `sha-<short>` | `ghcr.io/daniel-butler-irl/coinnode:sha-abc1234` | Any push |
| `v<semver>` | `ghcr.io/daniel-butler-irl/coinnode:v1.0.0` | Version tag |

## Usage

```bash
# Pull latest image
docker pull ghcr.io/daniel-butler-irl/coinnode:latest

# Verify attestation
gh attestation verify oci://ghcr.io/daniel-butler-irl/coinnode:latest --owner daniel-butler-irl

# Create a release
git tag v1.0.0
git push origin v1.0.0
```
