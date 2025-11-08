# Stalwart Mail Server Helm Chart

A Helm chart for deploying [Stalwart Mail Server](https://stalw.art/) on Kubernetes.

## Features

- **Flexible Deployment Modes**: Deploy as a single instance (Deployment) or in high-availability cluster mode (StatefulSet)
- **NATS Clustering**: Built-in support for clustered deployments using NATS for coordination
- **FoundationDB Storage**: Integrated support for FoundationDB as the backend storage layer
- **TLS Certificate Management**: Automated certificate provisioning via cert-manager
- **Comprehensive Mail Protocol Support**: SMTP, IMAP, POP3, and ManageSieve protocols
- **Configurable Logging**: Console and file-based logging with customizable levels

## Prerequisites

### Required

- **Kubernetes** 1.19 or later
- **Helm** 3.0 or later
- **cert-manager** v1.0+ for TLS certificate provisioning
- **FoundationDB cluster** 7.1+ configured and accessible
  - FDB cluster file must be available as a Kubernetes Secret
  - For TLS-enabled FDB, client certificates are required

### Optional (for Advanced Features)

- **NATS server** for high-availability clustering mode
- **External Secrets Operator** v0.9+ for dynamic FDB certificate management
- **Vault or OpenBao** for PKI certificate generation
- **acme-dns** server for automated DNS-01 challenge resolution

### FoundationDB Setup

Before installing this chart, you must have:

**Important - Custom Image Required:** The official Stalwart images on Docker Hub are not built with FoundationDB support. You must build a custom image using the `Dockerfile.fdb` from the Stalwart repository and configure the chart to use it:

```yaml
image:
  repository: your-registry.example.com/stalwart
  tag: v0.14.1-fdb
```

The `Dockerfile.fdb` can be found at: https://github.com/stalwartlabs/stalwart/blob/main/resources/docker/Dockerfile.fdb

1. A running FoundationDB cluster (v7.1+)
2. A Kubernetes Secret containing the FDB cluster file:
   ```bash
   kubectl create secret generic stalwart-fdb-cluster-file \
     --from-file=cluster-file=/path/to/fdb.cluster
   ```

3. (If using TLS) FDB client certificates configured via cert-manager or provided as a Secret

### Vault/OpenBao PKI Setup (Optional)

If enabling FDB client certificate provisioning (`fdbClientCert.enabled=true`):

1. Configure a PKI secrets engine in Vault/OpenBao
2. Create a Kubernetes auth role for the chart's ServiceAccount
3. Ensure the role has permissions to sign certificates and read the root CA
4. Provide the OpenBao CA certificate for VaultDynamicSecret authentication:

   **Important:** External Secrets Operator v1.0.0 does not support cross-namespace secret references for VaultDynamicSecret generators. You must provide the CA certificate inline or in the same namespace as the chart.

   **Option A: Inline CA Bundle (Recommended for GitOps)**
   ```bash
   # Get the CA certificate in base64 format
   CA_BUNDLE=$(kubectl get secret openbao-ca-cert -n external-secrets -o jsonpath='{.data.ca\.crt}')

   # Add to your values file
   helm install stalwart ./stalwart-chart \
     --set fdbClientCert.rootCA.caBundle="${CA_BUNDLE}"
   ```

   **Option B: Pre-create Secret in Chart Namespace**
   ```bash
   # Copy CA cert to the stalwart namespace
   kubectl get secret openbao-ca-cert -n external-secrets -o yaml | \
     sed 's/namespace: external-secrets/namespace: stalwart/' | \
     kubectl create -f -

   # Reference in values
   helm install stalwart ./stalwart-chart \
     --set fdbClientCert.rootCA.caSecretRef.name=openbao-ca-cert
   ```

## Installation

### Basic Installation

```bash
helm install stalwart ./stalwart-chart \
  --set stalwart.defaultHostname=mail.example.com \
  --set tls.dnsNames[0]=mail.example.com
```

### High Availability Cluster Mode

```bash
helm install stalwart ./stalwart-chart \
  --set clustering.enabled=true \
  --set clustering.replicas=3 \
  --set clustering.nats.addresses[0]=nats://nats-server:4222 \
  --set stalwart.defaultHostname=mail.example.com
```

## Configuration

The following table lists the configurable parameters and their default values. For a complete list, see [values.yaml](values.yaml).

### Common Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas (non-clustered mode) | `1` |
| `image.repository` | Stalwart container image repository | `stalwartlabs/stalwart` |
| `image.tag` | Image tag | `v0.14.1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `stalwart.defaultHostname` | Default mail server hostname | `mail.example.com` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `LoadBalancer` |
| `service.externalTrafficPolicy` | External traffic policy | `Local` |

### TLS Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tls.dnsNames` | DNS names for the certificate | `[]` |
| `tls.acmeDnsServer` | ACME DNS server URL | `https://acme-dns.example.com` |

### Clustering Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `clustering.enabled` | Enable clustered deployment | `false` |
| `clustering.replicas` | Number of cluster replicas | `3` |
| `clustering.nats.addresses` | NATS server addresses | `["nats://nats-server.default.svc.cluster.local:4222"]` |
| `clustering.nats.authEnabled` | Enable NATS authentication | `false` |

### FoundationDB Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `fdbClientCert.enabled` | Enable FDB client certificate provisioning | `false` |
| `fdbClientCert.issuer.server` | Vault/OpenBao server URL | `https://vault.example.com:8200` |

## Architecture

### Deployment Modes

#### Single Instance Mode (Default)
- Uses a standard Kubernetes Deployment
- Suitable for development and small deployments
- Single replica with persistent storage

#### Cluster Mode
- Uses a StatefulSet with pod anti-affinity
- Requires NATS for coordination between nodes
- Provides high availability and horizontal scaling
- Recommended for production deployments

### Storage Backend

Stalwart uses FoundationDB as its storage backend, providing:
- ACID transactions
- Horizontal scalability
- Built-in replication
- Multi-datacenter support

## Advanced Configuration

### Fallback Admin Account

For initial setup or emergency access:

```bash
helm install stalwart ./stalwart-chart \
  --set stalwart.fallbackAdmin.enabled=true
```

**Warning**: This should only be enabled temporarily for initial setup.

### File-Based Logging

Enable file tracer for WebUI log access:

```bash
helm install stalwart ./stalwart-chart \
  --set stalwart.tracer.enabled=true \
  --set stalwart.tracer.level=info
```

### Resource Limits

```yaml
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 1000m
    memory: 1Gi
```

## Upgrading

```bash
helm upgrade stalwart ./stalwart-chart
```

## Uninstalling

```bash
helm uninstall stalwart
```

## Troubleshooting

### Pods Not Starting

Check pod status and events:
```bash
kubectl describe pod -l app.kubernetes.io/name=stalwart
kubectl logs -l app.kubernetes.io/name=stalwart --tail=100
```

Common issues:
- **FDB cluster file not found**: Verify the Secret exists and contains valid cluster file
- **Image pull errors**: Check imagePullSecrets configuration
- **Resource limits**: Ensure sufficient cluster resources are available

### FoundationDB Connection Failures

1. Verify FDB cluster file is accessible:
   ```bash
   kubectl get secret stalwart-fdb-cluster-file
   ```

2. Check FDB client certificate (if TLS enabled):
   ```bash
   kubectl get certificate stalwart-fdb-client
   kubectl describe certificate stalwart-fdb-client
   ```

3. Validate FDB connectivity from within the pod:
   ```bash
   kubectl exec -it <pod-name> -- cat /var/dynamic-conf/fdb.cluster
   ```

### Certificate Issues

Check certificate status:
```bash
kubectl get certificate
kubectl describe certificate stalwart-tls
kubectl describe certificate stalwart-fdb-client
```

View cert-manager logs:
```bash
kubectl logs -n cert-manager deploy/cert-manager
```

Common problems:
- **ACME DNS challenges failing**: Verify acme-dns server is reachable and credentials are correct
- **Vault/OpenBao auth failures**: Check ServiceAccount bindings and Vault role permissions
- **Certificate not ready**: Allow time for issuance (can take several minutes)

### Clustering Problems

If using cluster mode (`clustering.enabled=true`):

1. Verify all pods are running:
   ```bash
   kubectl get pods -l app.kubernetes.io/name=stalwart
   ```

2. Check NATS connectivity:
   ```bash
   kubectl logs -l app.kubernetes.io/name=stalwart | grep -i nats
   ```

3. Verify pod anti-affinity is not preventing scheduling:
   ```bash
   kubectl describe pod -l app.kubernetes.io/name=stalwart | grep -A5 "Events:"
   ```

### Service Not Accessible

For LoadBalancer services:
```bash
kubectl get svc stalwart
```

Check external IP assignment and ensure:
- LoadBalancer controller is running (e.g., MetalLB, cloud provider LB)
- Firewall rules allow traffic on mail ports (25, 587, 993, etc.)
- DNS records point to the correct external IP

### Logging and Debugging

Enable verbose logging:
```bash
helm upgrade stalwart ./stalwart-chart \
  --set stalwart.tracer.enabled=true \
  --set stalwart.tracer.level=debug
```

View configuration:
```bash
kubectl get configmap stalwart -o yaml
```

Access logs via WebUI (if tracer enabled):
1. Port-forward to the pod: `kubectl port-forward svc/stalwart 8080:8080`
2. Navigate to `http://localhost:8080/admin/logs`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This Helm chart is open source and available under the Apache License 2.0.

## Support

For issues and questions:
- [Stalwart Documentation](https://stalw.art/docs/)
- [GitHub Issues](https://github.com/stalwartlabs/stalwart)

## Acknowledgments

This chart was created to simplify the deployment of Stalwart Mail Server on Kubernetes, providing a production-ready configuration with sensible defaults and extensive customization options.
