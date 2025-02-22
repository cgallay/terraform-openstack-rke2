apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: snapshot-validation-webhook
  namespace: kube-system
spec:
  chart: snapshot-validation-webhook
  repo: https://piraeus.io/helm-charts
  version: 1.6.0
  targetNamespace: kube-system
  bootstrap: True
  valuesContent: |-
    resources:
      requests:
        cpu: 10m
        memory: 16Mi

    nodeSelector:
      node-role.kubernetes.io/master: "true"

    tolerations:
      - effect: NoExecute
        key: CriticalAddonsOnly
        operator: "Exists"
