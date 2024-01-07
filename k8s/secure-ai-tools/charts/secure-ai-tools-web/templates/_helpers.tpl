{{/*
Expand the name of the chart.
*/}}
{{- define "secure-ai-tools-web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "secure-ai-tools-web.fullname" -}}
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
{{- define "secure-ai-tools-web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "secure-ai-tools-web.labels" -}}
helm.sh/chart: {{ include "secure-ai-tools-web.chart" . }}
{{ include "secure-ai-tools-web.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "secure-ai-tools-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "secure-ai-tools-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "secure-ai-tools-web.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "secure-ai-tools-web.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
https://github.com/helm/helm-www/issues/1259#issuecomment-1591142628
*/}}
{{- define "generate_static_password_next_auth" -}}
{{- /* Create "tmp_vars_next_auth" dict inside ".Release" to store various stuff. */ -}}
{{- if not (index .Release "tmp_vars_next_auth") -}}
{{-   $_ := set .Release "tmp_vars_next_auth" dict -}}
{{- end -}}
{{- /* Some random ID of this password, in case there will be other random values alongside this instance. */ -}}
{{- $key := printf "%s_%s" .Release.Name "password_next_auth" -}}
{{- /* If $key does not yet exist in .Release.tmp_vars_next_auth, then... */ -}}
{{- if not (index .Release.tmp_vars_next_auth $key) -}}
{{- /* ... store random password under the $key */ -}}
{{-   $_ := set .Release.tmp_vars_next_auth $key (randAlphaNum 20) -}}
{{- end -}}
{{- /* Retrieve previously generated value. */ -}}
{{- index .Release.tmp_vars_next_auth $key -}}
{{- end -}}

{{- define "random_pw_reusable_next_auth" -}}
  {{- if .Release.IsUpgrade -}}
    {{- $data := default dict (lookup "v1" "Secret" .Release.Namespace .Values.random_pw_secret_name_next_auth).data -}}
    {{- if $data -}}
      {{- index $data .Values.random_pw_secret_key_next_auth | b64dec -}}
    {{- end -}}
  {{- else -}}
    {{- if and (required "You must pass .Values.random_pw_secret_name_next_auth (the name of a secret to retrieve password from on upgrade)" .Values.random_pw_secret_name_next_auth) (required "You must pass .Values.random_pw_secret_key_next_auth (the name of the key in the secret to retrieve password from on upgrade)" .Values.random_pw_secret_key_next_auth) -}}
      {{- $data := default dict (lookup "v1" "Secret" .Release.Namespace .Values.random_pw_secret_name_next_auth).data -}}
      {{- if $data -}}
        {{- index $data .Values.random_pw_secret_key_next_auth | b64dec -}}
      {{- else -}}
        {{- (include "generate_static_password_next_auth" .) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
https://github.com/helm/helm-www/issues/1259#issuecomment-1591142628
*/}}
{{- define "generate_static_password_analytics" -}}
{{- /* Create "tmp_vars_analytics" dict inside ".Release" to store various stuff. */ -}}
{{- if not (index .Release "tmp_vars_analytics") -}}
{{-   $_ := set .Release "tmp_vars_analytics" dict -}}
{{- end -}}
{{- /* Some random ID of this password, in case there will be other random values alongside this instance. */ -}}
{{- $key := printf "%s_%s" .Release.Name "password_analytics" -}}
{{- /* If $key does not yet exist in .Release.tmp_vars_analytics, then... */ -}}
{{- if not (index .Release.tmp_vars_analytics $key) -}}
{{- /* ... store random password under the $key */ -}}
{{-   $_ := set .Release.tmp_vars_analytics $key (randAlphaNum 20) -}}
{{- end -}}
{{- /* Retrieve previously generated value. */ -}}
{{- index .Release.tmp_vars_analytics $key -}}
{{- end -}}

{{- define "random_pw_reusable_analytics" -}}
  {{- if .Release.IsUpgrade -}}
    {{- $data := default dict (lookup "v1" "Secret" .Release.Namespace .Values.random_pw_secret_name_analytics).data -}}
    {{- if $data -}}
      {{- index $data .Values.random_pw_secret_key_analytics | b64dec -}}
    {{- end -}}
  {{- else -}}
    {{- if and (required "You must pass .Values.random_pw_secret_name_analytics (the name of a secret to retrieve password from on upgrade)" .Values.random_pw_secret_name_analytics) (required "You must pass .Values.random_pw_secret_key_analytics (the name of the key in the secret to retrieve password from on upgrade)" .Values.random_pw_secret_key_analytics) -}}
      {{- $data := default dict (lookup "v1" "Secret" .Release.Namespace .Values.random_pw_secret_name_analytics).data -}}
      {{- if $data -}}
        {{- index $data .Values.random_pw_secret_key_analytics | b64dec -}}
      {{- else -}}
        {{- (include "generate_static_password_analytics" .) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
