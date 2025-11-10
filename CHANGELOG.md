# Changelog

All notable changes to the Stalwart Helm Chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-11-10

### Added
- **OpenTelemetry Metrics Export**: New `stalwart.metrics.otel` configuration for exporting metrics to OpenTelemetry Collector
  - `stalwart.metrics.otel.enabled` - Enable/disable metrics export (default: false)
  - `stalwart.metrics.otel.transport` - Transport protocol: "grpc" or "http" (default: "grpc")
  - `stalwart.metrics.otel.endpoint` - OTel Collector endpoint URL
  - `stalwart.metrics.otel.interval` - Metrics push interval (default: "30s")
  - Supports both gRPC (host:port) and HTTP (full URL with path) endpoints

- **OpenTelemetry Tracer Configuration**: New `stalwart.tracer.otel` for logs and traces export
  - `stalwart.tracer.otel.transport` - Transport protocol: "grpc" or "http" (default: "http")
  - `stalwart.tracer.otel.logsEndpoint` - OTel Collector logs endpoint URL
  - `stalwart.tracer.otel.tracesEndpoint` - OTel Collector traces endpoint URL
  - `stalwart.tracer.otel.level` - Log level for OTel export (default: "info")
  - `stalwart.tracer.otel.enableLogExporter` - Enable log export (default: true)
  - `stalwart.tracer.otel.enableSpanExporter` - Enable trace export (default: true)
  - `stalwart.tracer.otel.throttle` - Throttle duration between batches (default: "1s")
  - Creates separate tracer instances for logs and traces with dedicated endpoints

### Changed
- ConfigMap template now generates separate OpenTelemetry tracer configurations (`[tracer.otel-logs]` and `[tracer.otel-traces]`)
- OpenTelemetry configuration is opt-in and disabled by default to maintain backward compatibility

### Notes
- This release enables integration with OpenTelemetry-based observability platforms
- Stalwart metrics, logs, and traces can be sent to collectors like OpenTelemetry Collector for processing and forwarding to backends like VictoriaMetrics, VictoriaLogs, Tempo, or Jaeger
- All OpenTelemetry features are optional and disabled by default

## [0.3.0] - 2025-11-09

### Added
- Configurable console logger settings via `stalwart.tracer.console`
  - `stalwart.tracer.console.enabled` - Enable/disable console logging (default: true)
  - `stalwart.tracer.console.level` - Console log level: trace, debug, info, warn, error (default: "info")
  - `stalwart.tracer.console.ansi` - Enable ANSI color codes in console logs (default: true)
- Console logging can now be disabled or have its log level adjusted independently from file logging

### Changed
- Console tracer configuration is no longer hardcoded in the ConfigMap template
- Default console log level changed from "trace" to "info" for cleaner production logs
- File tracer configuration remains backward compatible at the same values path

## [0.2.1] - 2025-11-08

### Fixed
- **CRITICAL**: Fixed cert-manager Vault/OpenBao issuer authentication for FDB client certificates
  - Updated `fdb-client-issuer.yaml` template to automatically prepend `/v1/auth/` to `kubernetesAuthPath`
  - Resolves cert-manager error: `http2: invalid request :path "kubernetes/example-cluster/login"`
  - Users should now specify only the Vault mount point (e.g., `kubernetes/example-cluster`) instead of the full API path
  - This aligns with Vault's canonical path naming used elsewhere in the ecosystem

### Changed
- **BREAKING**: `fdbClientCert.issuer.kubernetesAuthPath` value format changed
  - **Old format**: `/v1/auth/kubernetes/example-cluster` (full Vault API path)
  - **New format**: `kubernetes/example-cluster` (Vault mount point only)
  - The chart now handles the `/v1/auth/` prefix internally for cert-manager compatibility
  - ESO VaultDynamicSecret continues to use the mount point format directly

### Migration Guide

If you're upgrading from 0.2.0, update your `kubernetesAuthPath` value:

```yaml
# OLD (0.2.0 and earlier)
fdbClientCert:
  issuer:
    kubernetesAuthPath: "/v1/auth/kubernetes/example-cluster"

# NEW (0.2.1+)
fdbClientCert:
  issuer:
    kubernetesAuthPath: "kubernetes/example-cluster"
```

## [0.2.0] - 2025-11-08

### Added
- New `annotations` value for configurable Deployment/StatefulSet metadata annotations
- Support for applying annotations to workload controllers (Deployment/StatefulSet) independently from pod annotations

### Fixed
- **IMPORTANT**: Stakater Reloader annotation placement corrected - now applies to Deployment/StatefulSet metadata instead of pod template metadata
  - This follows the correct Kubernetes pattern where Reloader watches workload resources, not pods
  - Prevents unnecessary pod restarts when annotations change
  - Aligns with official Stakater Reloader documentation

### Changed
- **BREAKING**: Removed hardcoded `reloader.stakater.com/auto: "true"` annotation from deployment.yaml and statefulset.yaml templates
  - Users who rely on Stakater Reloader must now explicitly set this annotation in their values:
    ```yaml
    annotations:
      reloader.stakater.com/auto: "true"
    ```
  - This change makes the chart more flexible and removes opinionated defaults

### Migration Guide

If you were previously relying on the automatic Stakater Reloader annotation, update your values file:

```yaml
# Add to your values.yaml or values override
annotations:
  reloader.stakater.com/auto: "true"
```

## [0.1.0] - 2025-11-08

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
