# Changelog

All notable changes to the Stalwart Helm Chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-08

Initial public release of the Stalwart Mail Server Helm chart.

### Features

**Deployment Modes**
- Single-instance deployment using Kubernetes Deployment
- High-availability cluster mode using StatefulSet with configurable replicas
- NATS-based clustering for coordination between cluster nodes
- Pod anti-affinity for optimal distribution across nodes

**Storage Backend**
- FoundationDB integration for scalable, distributed storage
- Configurable data compression (default: lz4)
- TLS support with configurable peer verification
- Init container for FDB cluster file seeding

**Certificate Management**
- Automated TLS certificate provisioning via cert-manager
- ACME DNS-01 challenge support for Let's Encrypt certificates
- Configurable ACME server URL (production/staging)
- FDB client certificate provisioning via Vault/OpenBao PKI
- External Secrets Operator v1.0.0 integration using VaultDynamicSecret generators

**Mail Server Capabilities**
- Support for SMTP, IMAP, POP3, and ManageSieve protocols
- Configurable default hostname
- Optional fallback admin account for initial setup
- Console and file-based logging with configurable levels

**Security**
- Pod security context enabled by default (non-root user UID 8080)
- All container capabilities dropped by default
- Privilege escalation disabled
- Configurable fsGroup for proper filesystem permissions
- FDB TLS peer verification with configurable security requirements

**Networking**
- LoadBalancer, NodePort, and ClusterIP service types
- Support for `loadBalancerIP` and `externalIPs` configuration
- External traffic policy configuration
- Comprehensive port definitions for all mail protocols

### Configuration Highlights

**Flexible FoundationDB Integration**
- `fdb.secrets.clusterFile` - Configurable FDB cluster file secret name
- `fdb.secrets.clientCert` - Configurable FDB client certificate secret name
- `fdb.compression` - Data compression algorithm (default: lz4)
- `fdb.tls.peerVerification` - TLS peer verification rules

**PKI and Certificate Configuration**
- `fdbClientCert.rootCA.caBundle` - Inline base64-encoded OpenBao CA certificate
- `fdbClientCert.rootCA.caSecretRef` - Reference to existing CA secret in same namespace
- `fdbClientCert.rootCA.path` - Vault PKI root CA path
- `fdbClientCert.rootCA.role` - Vault role for root CA access
- `certManager.namespace` - Configurable cert-manager namespace (default: cert-manager)
- `tls.acmeServer` - ACME server URL for Let's Encrypt integration

**Resource Management**
- Default resource requests: 500m CPU, 1Gi RAM
- Default resource limits: 2 CPU, 4Gi RAM
- Configurable for different deployment sizes

**Operational Flexibility**
- `initImage.*` - Configurable init container image for air-gapped environments
- `service.ports[].protocol` - Protocol field for all service ports
- `stalwart.tracer.*` - File-based logging configuration for WebUI access

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- cert-manager v1.0+
- External Secrets Operator v1.0.0+
- FoundationDB cluster 7.1+
- ClusterSecretStore configured for Vault/OpenBao access (if using FDB client certificates)

### Documentation

- Comprehensive README with prerequisites and installation instructions
- Detailed troubleshooting section covering common issues
- FoundationDB setup guide
- Vault/OpenBao PKI configuration examples
- Deployment architecture explanations
- Advanced configuration examples
- Post-installation NOTES.txt with certificate status checks

### Technical Details

- Chart version: 0.1.0
- App version: v0.14.1
- License: Apache License 2.0
- Chart follows Helm best practices
- Values.yaml uses helm-docs compatible comment format
- All templates use consistent spacing and indentation

### External Secrets Operator Integration

This chart uses VaultDynamicSecret generators for accessing Vault/OpenBao PKI endpoints, which is the canonical approach for non-KV Vault secrets engines. The chart requires the OpenBao CA certificate to be provided either inline (`fdbClientCert.rootCA.caBundle`) or via a secret reference in the same namespace (`fdbClientCert.rootCA.caSecretRef`) as ESO v1.0.0 does not support cross-namespace secret references for generators by design.
