{{/*
Expand the name of the chart.
*/}}
{{- define "illumidesk.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "illumidesk.fullname" -}}
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

{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Return the Database hostname
*/}}
{{- define "database.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-%s.%s.%s" .Release.Name "postgresql" .Release.Namespace "svc.cluster.local" -}}
{{- else if .Values.externaldb.enabled }}
{{- printf "%s" .Values.externaldb.host -}}
{{- end -}}
{{- end -}}


{{/*
Return the Database port
*/}}
{{- define "database.port" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "5432" | quote -}}
{{- else -}}
    {{- .Values.externalDatabase.port | quote -}}
{{- end -}}
{{- end -}}

{{/*
Return the Database database name
*/}}
{{- define "database.name" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%s" .Values.postgresql.postgresqlDatabase -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the Database user
*/}}
{{- define "database.databaseUser" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%s" .Values.postgresql.postgresqlUsername -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.username -}}
{{- end -}}
{{- end -}}

{{/*
Return the Database encrypted password
*/}}
{{- define "database.databaseEncryptedPassword" -}}
{{- if .Values.postgresql.enabled }}
    {{- .Values.postgresql.postgresqlPassword | b64enc | quote -}}
{{- else -}}
    {{- .Values.externalDatabase.password | b64enc | quote -}}
{{- end -}}
{{- end -}}
