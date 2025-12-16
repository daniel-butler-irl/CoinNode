# Prompts

> create a helm chart for the bitcoin node image in this repo, it should have helthchecks, readiness/liveness probes, reqource qoutas and limits/requests. it should use a stateful set and perstent volumes with rook and ceph for data resilencey. consider security and reliablity

**AI PLAN**

  Helm Chart for Bitcoin Node - Implementation Plan

 Overview

 Create a production-ready Helm chart for Bitcoin Core 29.0 with StatefulSet, Rook/Ceph storage, health probes,
 security hardening, and network-specific value files.

 Chart Location

 orchestration/charts/bitcoin-node/

 File Structure

 orchestration/charts/bitcoin-node/
 ├── Chart.yaml                    # Chart metadata (v0.1.0, appVersion 29.0)
 ├── values.yaml                   # Default configuration (mainnet)
 ├── values-mainnet.yaml           # Mainnet overrides (700Gi storage)
 ├── values-testnet.yaml           # Testnet overrides (50Gi storage)
 ├── README.md                     # Usage docs + Rook/Ceph setup guide
 ├── .helmignore
 └── templates/
     ├── _helpers.tpl              # Template helpers
     ├── NOTES.txt                 # Post-install instructions
     ├── statefulset.yaml          # Core workload
     ├── service-rpc.yaml          # ClusterIP for RPC (internal only)
     ├── service-p2p.yaml          # NodePort for P2P (external)
     ├── service-headless.yaml     # Headless for StatefulSet
     ├── configmap.yaml            # bitcoin.conf
     ├── secret.yaml               # RPC credentials
     ├── networkpolicy.yaml        # Network security rules
     ├── serviceaccount.yaml       # Dedicated SA
     ├── poddisruptionbudget.yaml  # PDB for HA
     └── tests/
         └── test-connection.yaml  # Helm test

 Key Configurations

 StatefulSet

 - Replicas: 1 (blockchain nodes are not horizontally scalable)
 - terminationGracePeriodSeconds: 600 (10 min for clean DB shutdown)
 - updateStrategy: RollingUpdate
 - podManagementPolicy: OrderedReady

 Probes

 | Probe     | Command                       | Initial | Period | Timeout | Failures        |
 |-----------|-------------------------------|---------|--------|---------|-----------------|
 | Startup   | bitcoin-cli getblockchaininfo | 60s     | 60s    | 30s     | 10080 (~7 days) |
 | Liveness  | bitcoin-cli getblockchaininfo | 30s     | 30s    | 10s     | 5               |
 | Readiness | bitcoin-cli getblockchaininfo | 30s     | 30s    | 10s     | 3               |

 Resources

 resources:
   requests:
     cpu: 500m
     memory: 2Gi
   limits:
     cpu: "4"
     memory: 8Gi

 Persistent Volume (Rook/Ceph)

 - StorageClass: rook-ceph-block
 - Access Mode: ReadWriteOnce
 - Mainnet: 700Gi
 - Testnet: 50Gi
 - Retain on delete: true

 Security Context (Pod Security Standards: Restricted)

 podSecurityContext:
   runAsNonRoot: true
   runAsUser: 1000
   runAsGroup: 1000
   fsGroup: 1000
   seccompProfile:
     type: RuntimeDefault

 containerSecurityContext:
   allowPrivilegeEscalation: false
   readOnlyRootFilesystem: true
   capabilities:
     drop: [ALL]

 Network Policy

 - P2P Ingress: Allow from anywhere (required for blockchain)
 - RPC Ingress: Restricted to specified namespaces
 - Egress: DNS + P2P ports only

 Services

 | Service  | Type             | Purpose                          |
 |----------|------------------|----------------------------------|
 | RPC      | ClusterIP        | Internal RPC access only         |
 | P2P      | NodePort         | External blockchain connectivity |
 | Headless | ClusterIP (None) | StatefulSet DNS                  |

 Implementation Steps

 Phase 1: Chart Scaffolding

 1. Create directory structure at orchestration/charts/bitcoin-node/
 2. Create Chart.yaml with metadata
 3. Create _helpers.tpl with label/name helpers
 4. Create .helmignore

 Phase 2: Core Workload

 5. Create values.yaml with all defaults
 6. Create statefulset.yaml with:
   - Container from ghcr.io/daniel-butler-irl/coinnode
   - Environment: BITCOIN_NETWORK, BITCOIN_DATA
   - Volume mounts: data PVC, config ConfigMap, tmp emptyDir
   - All three probes using bitcoin-cli
   - Security contexts
 7. Create configmap.yaml for bitcoin.conf
 8. Create secret.yaml for RPC credentials

 Phase 3: Networking

 9. Create service-headless.yaml for StatefulSet
 10. Create service-rpc.yaml (ClusterIP)
 11. Create service-p2p.yaml (NodePort)
 12. Create networkpolicy.yaml

 Phase 4: Security & Reliability

 13. Create serviceaccount.yaml
 14. Create poddisruptionbudget.yaml

 Phase 5: Network-Specific Values

 15. Create values-mainnet.yaml (700Gi, ports 8332/8333)
 16. Create values-testnet.yaml (50Gi, ports 18332/18333)

 Phase 6: Documentation & Testing

 17. Create NOTES.txt with post-install instructions
 18. Create tests/test-connection.yaml
 19. Create README.md with:
   - Installation instructions
   - Configuration reference
   - Rook/Ceph StorageClass setup example
   - Security considerations

 Reference Files

 - /Users/ruralledge/repos/CoinNode/docker/Dockerfile - Container config (UID 1000, ports, healthcheck)
 - /Users/ruralledge/repos/CoinNode/docker/entrypoint.sh - Env vars, graceful shutdown

 Container Image

 - Repository: ghcr.io/daniel-butler-irl/coinnode
 - Tag: Use specific version tags in production (not latest)

 Port Mappings

 | Network | RPC   | P2P   |
 |---------|-------|-------|
 | Mainnet | 8332  | 8333  |
 | Testnet | 18332 | 18333 |
 | Regtest | 18443 | 18444 |
 | Signet  | 38332 | 38333 |
