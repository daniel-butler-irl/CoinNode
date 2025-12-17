# Orchestration

This directory contains Kubernetes manifests for deploying the Bitcoin node. The manifests define a Deployment, services, configuration, storage, and network policies.

## Why Deployment over StatefulSet

The initial implementation used a StatefulSet, but this was changed to a Deployment for the following reasons:

- **No scaling planned:** This deployment is single-replica by design. Bitcoin nodes each require their own full blockchain copy, and we have no requirement for multiple replicas. StatefulSet's per-pod volume provisioning and ordered scaling are therefore unused.
- **Single replica**: With `replicas: 1`, StatefulSet features like stable network identity (`bitcoin-node-0`) and ordered deployment are unnecessary.
- **Simpler architecture**: A Deployment with a standalone PVC and `Recreate` strategy provides identical persistence guarantees with a more conventional pattern.
- **Spec alignment**: The requirements suggest "Use Deployment (or StatefulSet if you justify persistence needs)" - a Deployment is the expected default.

## Security Hardening

The container is security hardened following best practices. It runs as a non-root user with a read-only root filesystem, drops all Linux capabilities, disables privilege escalation, and does not mount a service account token. These constraints reduce the attack surface and limit what an attacker could do if they compromised the container.

## Configuration

I configured the node to run in regtest mode for simplicity. Regtest is a private local network that does not connect to the public Bitcoin network, which keeps everything self-contained and avoids needing to sync the full blockchain.

Configuration is stored separately from data:
- **Data directory**: `/var/lib/bitcoin`
- **Config file**: `/etc/bitcoin/bitcoin.conf`

### Deploy

```sh
kubectl apply -f orchestration/
```

### Verify

```sh
kubectl get pods -l app=bitcoin-node
kubectl logs -l app=bitcoin-node
```
