# Prompts

> create kubernetes manifests to deploy the bitcoin node container to kubernetes. use a statefulset for blockchain data persistence with proper health checks using bitcoin-cli. include security hardening with network policies, pod disruption budget, and run as non-root user with read-only filesystem. configure for regtest network for development. include configmap for bitcoin.conf, secret for rpc credentials, and a serviceaccount with disabled token mounting.

**AI PLAN**

Kubernetes Orchestration Plan for Bitcoin Node

Overview

Create production-ready Kubernetes manifests to deploy the containerized
Bitcoin Core node with security hardening and reliability.

Files to Create

1. orchestration/statefulset.yaml

StatefulSet configuration:
- Single replica for blockchain node
- Headless service reference for DNS-based pod identity
- Container image: bitcoin-node:local (local development)
- Regtest mode configuration (ports 18443 RPC, 18444 P2P)
- Resource limits: 512Mi-1Gi memory, 100m-1000m CPU
- Security context: non-root (UID 1000), read-only rootfs, no privilege escalation
- Health probes using bitcoin-cli getblockchaininfo
- 600-second termination grace period for graceful shutdown
- Volume mounts for data, config, and tmp directories

2. orchestration/service.yaml

Two service definitions:
- Headless service (ClusterIP: None) for StatefulSet DNS discovery
- Standard ClusterIP service exposing RPC port for in-cluster access

3. orchestration/configmap.yaml

Bitcoin Core configuration (bitcoin.conf):
- server=1, listen=1, printtoconsole=1
- RPC configuration for cluster access
- dbcache=450, maxconnections=40
- disablewallet=1 (node-only mode)
- Regtest network bindings

4. orchestration/secret.yaml

Opaque secret containing:
- rpc-user: bitcoinrpc
- rpc-password: changeme-in-production (placeholder)

5. orchestration/pvc.yaml

PersistentVolumeClaim:
- 1Gi storage request
- ReadWriteOnce access mode
- Default storage class

6. orchestration/networkpolicy.yaml

Network isolation rules:
- Ingress: Allow RPC (18443) from cluster, P2P (18444) from any
- Egress: Allow DNS (53) to all namespaces, P2P (18444) to any
- Default deny for all other traffic

7. orchestration/pdb.yaml

PodDisruptionBudget:
- minAvailable: 1
- Protects against voluntary disruptions during maintenance

8. orchestration/serviceaccount.yaml

ServiceAccount:
- automountServiceAccountToken: false
- Prevents container from accessing Kubernetes API

Security Features

- Non-root user execution (UID 1000)
- Read-only root filesystem
- No privilege escalation
- Network policies with explicit allow rules
- Service account token disabled
- Pod disruption budget protection

Resource Configuration

| Resource | Request | Limit |
|----------|---------|-------|
| Memory   | 512Mi   | 1Gi   |
| CPU      | 100m    | 1000m |
| Storage  | 1Gi     | -     |

Network Configuration

| Port  | Protocol | Purpose |
|-------|----------|---------|
| 18443 | TCP      | RPC     |
| 18444 | TCP      | P2P     |

Naming Conventions

- Label selector: app: bitcoin-node
- Resource names: bitcoin-node-{function}
- Port names: rpc, p2p

Usage

# Apply all manifests
kubectl apply -f orchestration/

# Check pod status
kubectl get pods -l app=bitcoin-node

# View logs
kubectl logs -f -l app=bitcoin-node

# Access RPC (from within cluster)
kubectl run -it --rm debug --image=curlimages/curl -- \
  curl -u bitcoinrpc:changeme-in-production \
  http://bitcoin-node-rpc:18443 \
  -d '{"method":"getblockchaininfo"}'
