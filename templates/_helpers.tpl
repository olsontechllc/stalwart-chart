{{/*
Expand the name of the chart.
*/}}
{{- define "stalwart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "stalwart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "stalwart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "stalwart.labels" -}}
helm.sh/chart: {{ include "stalwart.chart" . }}
{{ include "stalwart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "stalwart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stalwart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "stalwart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "stalwart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
FoundationDB volumes
Defines all volumes needed for FDB integration
*/}}
{{- define "stalwart.fdb.volumes" -}}
# FoundationDB cluster file secret
- name: fdb-cluster-secret
  secret:
    secretName: {{ .Values.fdb.secrets.clusterFile }}
# FDB client certificate for mTLS authentication
- name: fdb-client-certs
  secret:
    secretName: {{ .Values.fdb.secrets.clientCert }}
    defaultMode: 0400
# FDB root CA for server certificate validation
- name: fdb-root-ca
  secret:
    secretName: {{ include "stalwart.fullname" . }}-fdb-root-ca
    defaultMode: 0444
# Writable volume for FDB client library
- name: dynamic-conf
  emptyDir: {}
{{- end }}

{{/*
FoundationDB environment variables
Defines all environment variables needed for FDB client configuration
*/}}
{{- define "stalwart.fdb.env" -}}
# FoundationDB client configuration
- name: FDB_CLUSTER_FILE
  value: /var/dynamic-conf/fdb.cluster
- name: FDB_TLS_CERTIFICATE_FILE
  value: /etc/fdb-client-certs/tls.crt
- name: FDB_TLS_KEY_FILE
  value: /etc/fdb-client-certs/tls.key
- name: FDB_TLS_CA_FILE
  value: /etc/fdb-root-ca/ca.crt
- name: FDB_TLS_VERIFY_PEERS
  value: {{ .Values.fdb.tls.peerVerification | quote }}
{{- end }}

{{/*
FoundationDB init container
Defines the init container that seeds the FDB cluster file
*/}}
{{- define "stalwart.fdb.initContainer" -}}
# FDB cluster file init container
# Copies the FoundationDB cluster file from a read-only Secret to a writable emptyDir
# This allows the FDB client library to update the cluster file as needed
- name: seed-cluster-file
  image: "{{ .Values.initImage.repository }}:{{ .Values.initImage.tag }}"
  imagePullPolicy: {{ .Values.initImage.pullPolicy }}
  command:
  - sh
  - -c
  - |
    cp /var/fdb-secret/cluster-file /var/dynamic-conf/fdb.cluster
    echo "FDB cluster file seeded successfully"
    cat /var/dynamic-conf/fdb.cluster
  volumeMounts:
  - name: fdb-cluster-secret
    mountPath: /var/fdb-secret
    readOnly: true
  - name: dynamic-conf
    mountPath: /var/dynamic-conf
{{- end }}
