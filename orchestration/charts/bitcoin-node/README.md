# Bitcoin Node Helm Chart

A production-ready Helm chart for deploying Bitcoin Core 29.0 on Kubernetes with StatefulSet, Rook/Ceph persistent storage, and enterprise-grade security.

## Features

- **StatefulSet** deployment for blockchain data persistence
- **Rook/Ceph** integration for distributed storage resilience
- **Pod Security Standards** (Restricted profile) compliance
- **NetworkPolicies** for network segmentation
- **Health probes** (startup, liveness, readiness)
- **Resource quotas** and limits
- **Multi-network support** (mainnet, testnet, regtest, signet)

## Prerequisites

- Kubernetes 1.25+
- Helm 3.10+
- Rook/Ceph storage cluster with `rook-ceph-block` StorageClass

### Setting up Rook/Ceph StorageClass

If you don't have Rook/Ceph installed, follow these steps:

1. **Install Rook Operator:**
```bash
kubectl create namespace rook-ceph
kubectl apply -f https://raw.githubusercontent.com/rook/rook/v1.14.0/deploy/examples/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/v1.14.0/deploy/examples/common.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/v1.14.0/deploy/examples/operator.yaml
```

2. **Create Ceph Cluster:**
```bash
kubectl apply -f https://raw.githubusercontent.com/rook/rook/v1.14.0/deploy/examples/cluster.yaml
```

3. **Create Block StorageClass:**
```yaml
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph
  pool: replicapool
  imageFormat: "2"
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
  csi.storage.k8s.io/fstype: ext4
reclaimPolicy: Retain
allowVolumeExpansion: true
```

## Installation

### Mainnet (Full Node)
```bash
helm install bitcoin ./bitcoin-node -f values-mainnet.yaml
```

### Testnet
```bash
helm install bitcoin-testnet ./bitcoin-node -f values-testnet.yaml
```

### Custom Configuration
```bash
helm install bitcoin ./bitcoin-node \
  --set bitcoin.network=mainnet \
  --set persistence.size=1000Gi \
  --set resources.limits.memory=16Gi
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image | `ghcr.io/daniel-butler-irl/coinnode` |
| `image.tag` | Image tag | `latest` |
| `bitcoin.network` | Bitcoin network | `mainnet` |
| `bitcoin.rpc.user` | RPC username | `bitcoinrpc` |
| `bitcoin.rpc.password` | RPC password (auto-generated if empty) | `""` |
| `persistence.storageClass` | Storage class name | `rook-ceph-block` |
| `persistence.size` | PVC size | `700Gi` |
| `resources.requests.memory` | Memory request | `2Gi` |
| `resources.limits.memory` | Memory limit | `8Gi` |

### Storage Sizing Guide

| Network | Recommended Size | Notes |
|---------|-----------------|-------|
| Mainnet (full) | 700Gi+ | ~630GB as of 2024, growing ~60GB/year |
| Mainnet (pruned) | 10Gi | Set `prune=550` in bitcoin.config |
| Testnet | 50Gi | Smaller test network |
| Signet | 5Gi | Much smaller test network |
| Regtest | 1Gi | Local testing only |

### Bitcoin Configuration

Additional bitcoin.conf settings can be provided via `bitcoin.config`:

```yaml
bitcoin:
  config: |
    # Increase database cache (MB)
    dbcache=1000
    # Limit peer connections
    maxconnections=50
    # Enable transaction index
    txindex=1
    # Prune blockchain (MiB, 0=disabled)
    prune=0
```

## Security

This chart implements Kubernetes Pod Security Standards (Restricted profile):

- Runs as non-root user (UID 1000)
- Read-only root filesystem
- No privilege escalation
- Drops all Linux capabilities
- Seccomp profile enabled
- NetworkPolicy restricts traffic

### RPC Security

- RPC service is ClusterIP only (not exposed externally)
- RPC credentials stored in Kubernetes Secret
- NetworkPolicy limits RPC access to specified namespaces

## Monitoring

### Check Sync Progress
```bash
kubectl exec -it bitcoin-0 -- bitcoin-cli getblockchaininfo
```

### View Logs
```bash
kubectl logs -f bitcoin-0
```

### Check Resource Usage
```bash
kubectl top pod bitcoin-0
```

## Uninstallation

```bash
helm uninstall bitcoin
```

**Warning:** The PersistentVolumeClaim is retained by default. To delete blockchain data:
```bash
kubectl delete pvc data-bitcoin-bitcoin-node-0
```

## Troubleshooting

### Pod stuck in Pending
Check if the StorageClass exists and has available capacity:
```bash
kubectl get sc rook-ceph-block
kubectl get cephcluster -n rook-ceph
```

### Pod CrashLoopBackOff
Check logs for startup errors:
```bash
kubectl logs bitcoin-0 --previous
```

### Slow Sync
Increase database cache in values:
```yaml
bitcoin:
  config: |
    dbcache=2000
```

## License

MIT
