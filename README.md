# CoinNode

Sample Bitcoin Node Deployment

- Containerized Bitcoin Core 29.0 node
- Vanilla manifets for deploy to K8S
- CICD in GHA
- Log analisis with shell script and python

## AI Disclosure

This codebase was developed with the assistance of AI tooling, primarily Claude Code (Opus 4.5). All prompts and context inputs were authored by me.

AI assistance was used as a development aid — similar to tools such as linters, calculators, or IDE autocomplete — to help reason, iterate, and generate code suggestions. AI outputs were guided by carefully structured inputs and reviewed in full; nothing was accepted without human oversight.

I am fully responsible for the design, correctness, and maintenance of this codebase, and I can explain and modify any part of it as if it had been written entirely by hand.

My AI workflow is to work with the AI in Plan mode to define the problem and high level solution. Generate a base with that plan. Then manually review, and refactor as needed.

## Pre-commit

A standard set of pre-commit hooks has been added to the repository to catch common issues before changes leave a developer’s machine. These checks enforce basic formatting and validation, perform static analysis on Terraform and Docker files, and scan for common security issues such as accidentally committed secrets. The goal is to shift feedback as far left as possible, reducing avoidable CI failures and preventing sensitive data from ever reaching source control.

### Installing pre-commit

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


### Build and Run container

Build the image:

```sh
docker build -t bitcoin-core:29.0 docker/
```

Run a quick sanity check in regtest mode (private, local-only network):

```sh
docker run --rm -e BITCOIN_NETWORK=regtest bitcoin-core:29.0
```
