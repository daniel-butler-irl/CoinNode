# Orchestration

This directory contains Kubernetes manifests for deploying the Bitcoin node. The manifests define a StatefulSet, services, configuration, storage, and network policies.

The container is security hardened following best practices. It runs as a non-root user with a read-only root filesystem, drops all Linux capabilities, disables privilege escalation, and does not mount a service account token. These constraints reduce the attack surface and limit what an attacker could do if they compromised the container.

I configured the node to run in regtest mode for simplicity. Regtest is a private local network that does not connect to the public Bitcoin network, which keeps everything self-contained and avoids needing to sync the full blockchain.

### Deploy

```sh
kubectl apply -f orchestration/
```

### Verify

```sh
kubectl get pods -l app=bitcoin-node
kubectl logs -l app=bitcoin-node
```
