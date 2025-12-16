# CI

The pre-commit stage runs in CI as a safety net. Developers may skip or forget to set up pre-commit locally, so running it in the pipeline ensures that linting, validation, and secret detection still happen before code is merged. The goal is to shift left and catch as many issues as possible on the developer's workstation before they are committed, but CI provides a backstop when that doesn't happen.

For authentication to the container registry, I chose keyless signing with OIDC rather than stored secrets. This improves security because there are no long-lived credentials to leak or rotate. GitHub Actions requests a short-lived token from the identity provider at runtime, and the token is scoped to the specific workflow run. This also simplifies maintenance since there are no secrets to manage or renew.

Container images are scanned with Trivy before being pushed to the registry. The scan is configured to fail the pipeline on critical and high severity vulnerabilities, and the results are uploaded to the GitHub Security tab for visibility. This ensures that known vulnerabilities are caught before images reach production.

Build attestations are generated for supply chain verification. Each image includes SLSA provenance metadata that records how and where it was built. This allows consumers to verify the integrity of the image and confirm it was produced by this pipeline.

GitHub Actions workflow files are located in `.github/workflows/` as required by GitHub. See that directory for the pipeline configuration.

### Pull and Verify Image

```sh
docker pull ghcr.io/daniel-butler-irl/coinnode:latest
gh attestation verify oci://ghcr.io/daniel-butler-irl/coinnode:latest --owner daniel-butler-irl
```
