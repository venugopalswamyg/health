{{- define "healthcare-app.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "healthcare-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "healthcare-app.serviceAccountName" -}}
{{- printf "%s-sa" .Release.Name -}}
{{- end -}}
