{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cilium.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Render full image uri from given values, e.g:
```
optional 
global.imageRegistry:
image:
  registry: quay.io
  repository: cilium/cilium
  tag: v1.10.1
  useDigest: true
  digest: abcdefgh
```
then `include "image.url" (list $ . .Values.image)`
will return `quay.io/cilium/cilium:v1.10.1@abcdefgh` preferring the global.imageRegistry for all imageurls.
*/}}
{{- define "image.url" -}}
  {{- $globalContext := index . 0 }}
  {{- $localContext := index . 2 }}
  {{ with index . 1 }}
    {{- $global := $globalContext.Values.global | default dict -}}
    {{- $imageRegistry := $global.imageRegistry | default $localContext.registry -}}
    {{- $repository :=  $localContext.repository -}}
    {{- $tag := $localContext.tag | toString -}}
    {{- $digest := ($localContext.useDigest | default false) | ternary (printf "@%s" $localContext.digest) "" -}}
    {{- printf "%s/%s:%s%s" $imageRegistry $repository $tag $digest -}}
  {{- end -}}
{{- end -}}

{{/*
Return user specify priorityClass or default criticalPriorityClass
Usage:
  include "cilium.priorityClass" (list $ <priorityClass> <criticalPriorityClass>)
where:
* `priorityClass`: is user specify priorityClass e.g `.Values.operator.priorityClassName`
* `criticalPriorityClass`: default criticalPriorityClass, e.g `"system-cluster-critical"`
  This value is used when `priorityClass` is `nil` and
  `.Values.enableCriticalPriorityClass=true` and kubernetes supported it.
*/}}
{{- define "cilium.priorityClass" -}}
{{- $root := index . 0 -}}
{{- $priorityClass := index . 1 -}}
{{- $criticalPriorityClass := index . 2 -}}
{{- if $priorityClass }}
  {{- $priorityClass }}
{{- else if and $root.Values.enableCriticalPriorityClass $criticalPriorityClass -}}
  {{- if and (eq $root.Release.Namespace "kube-system") (semverCompare ">=1.10-0" $root.Capabilities.KubeVersion.Version) -}}
    {{- $criticalPriorityClass }}
  {{- else if semverCompare ">=1.17-0" $root.Capabilities.KubeVersion.Version -}}
    {{- $criticalPriorityClass }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "ingress.apiVersion" -}}
{{- if semverCompare ">=1.16-0, <1.19-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else if semverCompare "^1.19-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate backend for Hubble UI ingress.
*/}}
{{- define "ingress.paths" -}}
{{ if semverCompare ">=1.4-0, <1.19-0" .Capabilities.KubeVersion.Version -}}
backend:
  serviceName: hubble-ui
  servicePort: http
{{- else if semverCompare "^1.19-0" .Capabilities.KubeVersion.Version -}}
pathType: Prefix
backend:
  service:
    name: hubble-ui
    port:
      name: http
{{- end -}}
{{- end -}}
