{{/*
Expand the name of the chart.
*/}}
{{- define "bitcoin-node.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bitcoin-node.fullname" -}}
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
{{- define "bitcoin-node.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bitcoin-node.labels" -}}
helm.sh/chart: {{ include "bitcoin-node.chart" . }}
{{ include "bitcoin-node.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: blockchain-node
app.kubernetes.io/part-of: bitcoin
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bitcoin-node.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bitcoin-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bitcoin-node.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bitcoin-node.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the RPC port for the configured network
*/}}
{{- define "bitcoin-node.rpcPort" -}}
{{- $network := .Values.bitcoin.network }}
{{- if eq $network "mainnet" }}8332
{{- else if eq $network "testnet" }}18332
{{- else if eq $network "regtest" }}18443
{{- else if eq $network "signet" }}38332
{{- else }}8332
{{- end }}
{{- end }}

{{/*
Get the P2P port for the configured network
*/}}
{{- define "bitcoin-node.p2pPort" -}}
{{- $network := .Values.bitcoin.network }}
{{- if eq $network "mainnet" }}8333
{{- else if eq $network "testnet" }}18333
{{- else if eq $network "regtest" }}18444
{{- else if eq $network "signet" }}38333
{{- else }}8333
{{- end }}
{{- end }}

{{/*
Get the network flag for bitcoin-cli commands
*/}}
{{- define "bitcoin-node.networkFlag" -}}
{{- $network := .Values.bitcoin.network }}
{{- if eq $network "testnet" }}-testnet
{{- else if eq $network "regtest" }}-regtest
{{- else if eq $network "signet" }}-signet
{{- else }}
{{- end }}
{{- end }}
