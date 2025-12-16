# Prompts

> design a ci workflow for GHA put the actual workflows in CI directory and point to them. Use minimal secure actions prefering first parties like github. first stage should be to run the precommit in case a developer skipped it locally. Then build, scan and push the image to ghcr and create a release. Sign all artifacts and consider security as a high priority.

**AI PLAN**

  CI/CD Workflow Plan for CoinNode

 Overview

 Design a secure GitHub Actions CI pipeline with reusable
 workflows stored in the ci/ directory.

 Architecture

 .github/workflows/ci.yml          # Main orchestrator (triggers
 reusable workflows)
 ci/
 ├── pre-commit.yml                # Stage 1: Pre-commit checks
 ├── build.yml                     # Stage 2: Build, scan, push to
  GHCR
 └── release.yml                   # Stage 3: Create release with
 signed artifacts

 Security Principles

 1. First-party actions only - GitHub official actions (actions/,
 docker/, github/*)
 2. Pinned SHA versions - All actions pinned to full commit SHA
 (not tags)
 3. Minimal permissions - Each job gets only required permissions
 4. OIDC authentication - Keyless signing via Sigstore, no stored
 secrets for GHCR
 5. Supply chain attestations - SLSA provenance and SBOM
 generation
 6. Artifact signing - Container images signed with cosign via
 GitHub attestations

 Workflow Stages

 Stage 1: Pre-commit (ci/pre-commit.yml)

- Runs on: All pushes and PRs
- Purpose: Catch issues developers may have skipped locally
- Actions used:
  - actions/checkout@v4
  - actions/setup-python@v5
  - pre-commit/action@v3.0.1

 Stage 2: Build, Scan, Push (ci/build.yml)

- Runs on: Main branch pushes and tags
- Purpose: Build multi-arch image, scan for vulnerabilities, push
  to GHCR
- Actions used:
  - actions/checkout@v4
  - docker/setup-qemu-action@v3 (multi-arch)
  - docker/setup-buildx-action@v3
  - docker/login-action@v3 (GHCR via OIDC)
  - docker/metadata-action@v5 (OCI labels)
  - docker/build-push-action@v6
  - aquasecurity/trivy-action@0.28.0 (vulnerability scan)
  - actions/attest-build-provenance@v2 (SLSA attestation)
  - actions/attest-sbom@v2 (SBOM attestation)

 Stage 3: Release (ci/release.yml)

- Runs on: Version tags (v*..)
- Purpose: Create GitHub release with signed artifacts
- Actions used:
  - actions/checkout@v4
  - softprops/action-gh-release@v2 (create release)
  - actions/attest-build-provenance@v2

 Trigger Strategy

 | Event              | Pre-commit | Build | Release |
 |--------------------|------------|-------|---------|
 | Push to any branch | ✅         | ❌    | ❌      |
 | PR to main         | ✅         | ❌    | ❌      |
 | Push to main       | ✅         | ✅    | ❌      |
 | Tag v*..           | ✅         | ✅    | ✅      |

 Files to Create

 1. .github/workflows/ci.yml - Main workflow that:

- Calls reusable workflows from ci/ directory
- Handles conditional job execution
- Passes required inputs/secrets

 2. ci/pre-commit.yml - Reusable workflow:

- Sets up Python environment
- Installs and runs pre-commit with all hooks
- Caches pre-commit environments

 3. ci/build.yml - Reusable workflow:

- Multi-architecture build (amd64, arm64)
- Trivy vulnerability scanning (fail on CRITICAL/HIGH)
- Push to ghcr.io
- Generate SLSA provenance attestation
- Generate SBOM attestation

 4. ci/release.yml - Reusable workflow:

- Create GitHub release from tag
- Attach attestation artifacts
- Sign release with GitHub attestations

 Container Image Tags

- ghcr.io/{owner}/coinnode:latest - Latest main branch
- ghcr.io/{owner}/coinnode:sha-{short} - Commit SHA
- ghcr.io/{owner}/coinnode:v1.2.3 - Version tags

 Required Repository Settings

 After implementation, these settings should be enabled:

 1. Settings > Actions > General: Allow GitHub Actions
 2. Settings > Packages: Enable GHCR
 3. No secrets required (OIDC auth to GHCR)
