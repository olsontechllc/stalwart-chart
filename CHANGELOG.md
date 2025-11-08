# Changelog

All notable changes to the Stalwart Helm Chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-08

### Fixed
- OpenBao CA certificate secret is now only created if `fdbClientCert.openbaoCACert.caBundle` is provided
- This allows using existing secrets managed externally or in different namespaces
- Service template now supports `loadBalancerIP` and `externalIPs` fields

### Added
- Initial public release of Stalwart Mail Server Helm chart
- Support for single-instance and high-availability cluster deployments
- FoundationDB integration for scalable storage backend
- Automated TLS certificate management via cert-manager
- ACME DNS-01 challenge support for Let's Encrypt certificates
- FDB client certificate provisioning via Vault/OpenBao PKI
- External Secrets Operator integration for dynamic certificate management
- NATS-based clustering for high availability
- Comprehensive configuration options in values.yaml
- Configurable resource limits with production-ready defaults
- Pod security context with non-root user and capability dropping
- Support for all major mail protocols (SMTP, IMAP, POP3, ManageSieve)
- LoadBalancer, NodePort, and ClusterIP service types
- Optional fallback admin account for initial setup
- Console and file-based logging with configurable levels
- StatefulSet deployment mode for clustered installations
- Init container for FDB cluster file seeding
- Detailed NOTES.txt with post-installation guidance
- Comprehensive README with prerequisites and troubleshooting
- Production-ready Chart.yaml with metadata and keywords

### Configuration
- `certManager.namespace` - Configurable cert-manager namespace (default: `cert-manager`)
- `fdb.secrets.clusterFile` - Configurable FDB cluster file secret name
- `fdb.secrets.clientCert` - Configurable FDB client certificate secret name
- `fdb.compression` - Configurable FDB data compression algorithm (default: `lz4`)
- `fdb.tls.peerVerification` - Configurable FDB TLS peer verification rules
- `fdbClientCert.rootCA.path` - Configurable Vault PKI root CA path
- `fdbClientCert.rootCA.role` - Configurable Vault role for root CA access
- `tls.acmeServer` - Configurable ACME server URL (production/staging)
- `initImage.*` - Configurable init container image for air-gapped environments
- `service.ports[].protocol` - Protocol field for all service ports
- `resources` - Default resource limits (2 CPU, 4Gi RAM) and requests (500m CPU, 1Gi RAM)
- `podSecurityContext` - Run as non-root user (UID 8080) with fsGroup
- `securityContext` - Drop all capabilities, prevent privilege escalation

### Changed
- **BREAKING**: Service port definitions now require `protocol` field
- **BREAKING**: cert-manager namespace is now configurable (was hardcoded to `cozy-cert-manager`)
- License changed from MIT to Apache License 2.0
- Improved README with detailed prerequisites and troubleshooting sections
- Enhanced NOTES.txt with certificate status checks and troubleshooting commands
- Updated Chart.yaml with comprehensive metadata, keywords, and maintainer information
- All FDB-related settings now use configurable values instead of hardcoded strings
- Busybox init container image is now configurable for flexibility

### Security
- Enabled pod security context by default with non-root user
- Dropped all container capabilities by default
- Added fsGroup configuration for proper filesystem permissions
- Disabled privilege escalation in container security context
- FDB TLS peer verification now configurable for different security requirements

### Documentation
- Added detailed FoundationDB setup instructions
- Added Vault/OpenBao PKI configuration guide
- Added comprehensive troubleshooting section covering common issues
- Documented all breaking changes for migration from internal versions
- Added deployment architecture explanations
- Included examples for advanced configurations

### Maintenance
- Chart follows Helm best practices
- Values.yaml uses helm-docs compatible comment format
- All templates use consistent spacing and indentation
- Removed emoji from user-facing output for professional tone
