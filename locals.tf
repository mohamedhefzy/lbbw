locals {
  name_prefix     = "${var.lbbw_location}-${var.infra_environment}"
  prefix_app_name = "${var.app_environment}${var.app_name}"

  af_environment_long = var.infra_environment == "e" ? "dev" : "prod"

  default_helm_charts = {
    pmakskured = {
      name       = "kured"
      chart      = "kured"
      repository = "https://artifactory.lbbw.sko.de/artifactory/api/helm/skywalker-helm-${local.af_environment_long}"
      namespace  = "kured"
      version    = "5.10.0"

      set = [
        {
          name  = "image.repository"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/kubereboot/kured"
          type  = "string"
        },
        {
          name  = "image.pullSecrets[0].name"
          value = "artifactory-registry-secret"
          type  = "string"
        },
        {
          name  = "tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "tolerations[0].operator"
          value = "Exists"
          type  = "string"
        }
      ],
      set_list = [],
      values   = []
    },
    pmaksexternalsecrets = {
      name       = "external-secrets"
      chart      = "external-secrets"
      repository = "https://artifactory.lbbw.sko.de/artifactory/api/helm/skywalker-helm-${local.af_environment_long}"
      namespace  = "external-secrets"
      version    = "0.16.1"

      set = [
        {
          name  = "global.nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "global.tolerations[0].key"
          value = "CriticalAddonsOnly"
          type  = "string"
        },
        {
          name  = "global.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "global.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "image.repository"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/external-secrets/external-secrets"
          type  = "string"
        },
        {
          name  = "imagePullSecrets[0].name"
          value = "artifactory-registry-secret"
          type  = "string"
        },
        {
          name  = "certController.image.repository"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/external-secrets/external-secrets"
          type  = "string"
        },
        {
          name  = "certController.imagePullSecrets[0].name"
          value = "artifactory-registry-secret"
          type  = "string"
        },
        {
          name  = "webhook.image.repository"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/external-secrets/external-secrets"
          type  = "string"
        },
        {
          name  = "webhook.imagePullSecrets[0].name"
          value = "artifactory-registry-secret"
          type  = "string"
        }
      ],
      set_list = [],
      values   = []
    },
    pmaksingressnginx = {
      name       = "ingress-nginx"
      chart      = "ingress-nginx"
      repository = "https://artifactory.lbbw.sko.de/artifactory/api/helm/skywalker-helm-${local.af_environment_long}"
      namespace  = "infrastructure"
      version    = "4.12.1"

      set = [
        {
          name  = "controller.service.annotations.kubernetes\\.io/ingress\\.class"
          value = "nginx"
          type  = "string"
        },
        {
          name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
          value = "true"
          type  = "string"
        },
        {
          name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal-subnet"
          value = "snet-${var.app_environment}${var.app_name}-${var.helm.vnet_subnet_key}"
          type  = "string"
        },
        {
          name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
          value = "/healthz"
          type  = "string"
        },
        {
          name  = "controller.service.internal.enabled"
          value = true
          type  = "string"
        },
        {
          name  = "controller.service.externalTrafficPolicy"
          value = "Cluster"
          type  = "string"
        },
        {
          name  = "controller.tolerations[0].key"
          value = "CriticalAddonsOnly"
          type  = "string"
        },
        {
          name  = "controller.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "controller.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "controller.nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "controller.admissionWebhooks.patch.image.registry"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de"
          type  = "string"
        },
        {
          name  = "controller.admissionWebhooks.patch.tolerations[0].key"
          value = "CriticalAddonsOnly"
          type  = "string"
        },
        {
          name  = "controller.admissionWebhooks.patch.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "controller.admissionWebhooks.patch.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "controller.admissionWebhooks.patch.nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "controller.image.registry"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de"
          type  = "string"
        },
        {
          name  = "controller.opentelemetry.image.registry"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de"
          type  = "string"
        },
        {
          name  = "defaultBackend.enabled"
          value = true
          type  = "string"
        },
        {
          name  = "defaultBackend.image.registry"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de"
          type  = "string"
        },
        {
          name  = "defaultBackend.tolerations[0].key"
          value = "CriticalAddonsOnly"
          type  = "string"
        },
        {
          name  = "defaultBackend.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "defaultBackend.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "defaultBackend.nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "imagePullSecrets[0].name"
          value = "artifactory-registry-secret"
          type  = "string"
        }
      ],
      set_list = [],
      values   = []
    },
    pmaksmanagednginxaddon = {
      name       = "aks-managed-nginx-add-on"
      chart      = "aks-managed-nginx-add-on"
      repository = "https://artifactory.lbbw.sko.de/artifactory/api/helm/skywalker-helm-${local.af_environment_long}"
      namespace  = "app-routing-system"
      version    = "1.0.0"

      set = [
        {
          name  = "name"
          value = "nginx"
          type  = "string"
        },
        {
          name  = "spec.ingressClassName"
          value = "nginx"
          type  = "string"
        },
        {
          name  = "spec.controllerNamePrefix"
          value = "nginx-internal"
          type  = "string"
        },
        {
          name  = "spec.loadBalancerAnnotations.azureloadbalancerinternal"
          value = "true"
          type  = "string"
        },
        {
          name  = "spec.loadBalancerAnnotations.azureloadbalancerinternalsubnet"
          value = "snet-${var.app_environment}${var.app_name}-${var.helm.vnet_subnet_key}"
          type  = "string"
        }
      ],
      set_list = [],
      values   = []
    },
    pmaksexternaldns = {
      name       = "external-dns"
      chart      = "external-dns"
      repository = "https://artifactory.lbbw.sko.de/artifactory/api/helm/skywalker-helm-${local.af_environment_long}"
      namespace  = "external-dns"
      version    = "1.20.0"

      set = [
        {
          name  = "global.imagePullSecrets[0].name"
          value = "artifactory-registry-secret"
          type  = "string"
        },
        {
          name  = "image.repository"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/external-dns/external-dns"
          type  = "string"
        },
        {
          name  = "image.pullPolicy"
          value = "Always"
          type  = "string"
        },
        {
          name  = "provider.name"
          value = "azure-private-dns"
          type  = "string"
        },
        {
          name  = "sources[0]"
          value = "ingress"
          type  = "string"
        },
        {
          name  = "policy"
          value = "sync"
          type  = "string"
        },
        {
          name  = "dnsPolicy"
          value = "Default"
          type  = "string"
        },
        {
          name  = "registry"
          value = "txt"
          type  = "string"
        },
        {
          name  = "txtOwnerId"
          value = "external-dns"
          type  = "string"
        },
        {
          name  = "extraArgs.txt-wildcard-replacement"
          value = "wildcard"
          type  = "string"
        },
        {
          name  = "logLevel"
          value = "info"
          type  = "string"
        },
        {
          name  = "interval"
          value = "1m"
          type  = "string"
        },
        {
          name  = "nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "tolerations[0].key"
          value = "CriticalAddonsOnly"
          type  = "string"
        },
        {
          name  = "tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "podLabels.azure\\.workload\\.identity/use"
          value = "true"
          type  = "string"
        },
        {
          name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
          value = "${var.user_assigned_identity_default_mid_client_id}"
          type  = "string"
        },
        {
          name  = "serviceAccount.labels.azure\\.workload\\.identity/use"
          value = "true"
          type  = "string"
        },
        {
          name  = "resources.requests.cpu"
          value = "10m"
          type  = "string"
        },
        {
          name  = "resources.requests.memory"
          value = "32Mi"
          type  = "string"
        },
        {
          name  = "resources.limits.cpu"
          value = "50m"
          type  = "string"
        },
        {
          name  = "resources.limits.memory"
          value = "64Mi"
          type  = "string"
        },
        {
          name  = "domainFilters[0]"
          value = "${var.private_dns_zone_name}"
          type  = "string"
        }
      ],
      set_list = [],
      values = [
        yamlencode({
          secretConfiguration = {
            enabled   = true
            mountPath = "/etc/kubernetes"
            data = {
              "azure.json" = jsonencode({
                subscriptionId               = data.azurerm_client_config.current.subscription_id,
                tenantId                     = data.azurerm_client_config.current.tenant_id,
                resourceGroup                = var.private_dns_rg_name,
                useWorkloadIdentityExtension = true
              })
            }
          }
        })
      ]
    },
    pmaksdynatrace = {
      name       = "dynatrace-operator"
      chart      = "dynatrace-operator"
      repository = "oci://skywalker-oci-${local.af_environment_long}.artifactory.lbbw.sko.de"
      namespace  = "dynatrace"
      version    = "1.7.1"

      set = [
        {
          name  = "imageRef.repository"
          value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/dynatrace/dynatrace-operator"
          type  = "string"
        },
        {
          name  = "customPullSecret"
          value = "artifactory-registry-secret"
          type  = "string"
        },
        {
          name  = "operator.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "operator.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "operator.nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "operator.requests.cpu"
          value = "0m"
          type  = "string"
        },
        {
          name  = "operator.requests.memory"
          value = "0Mi"
          type  = "string"
        },
        {
          name  = "webhook.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "webhook.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "webhook.nodeSelector.nodepool"
          value = "default"
          type  = "string"
        },
        {
          name  = "webhook.requests.cpu"
          value = "0m"
          type  = "string"
        },
        {
          name  = "webhook.requests.memory"
          value = "0Mi"
          type  = "string"
        },
        {
          name  = "csidriver.tolerations[0].effect"
          value = "NoSchedule"
          type  = "string"
        },
        {
          name  = "csidriver.tolerations[0].operator"
          value = "Exists"
          type  = "string"
        },
        {
          name  = "csidriver.csiInit.resources.requests.cpu"
          value = "0m"
          type  = "string"
        },
        {
          name  = "csidriver.server.resources.requests.cpu"
          value = "0m"
          type  = "string"
        },
        {
          name  = "csidriver.provisioner.resources.requests.cpu"
          value = "0m"
          type  = "string"
        },
        {
          name  = "csidriver.registrar.resources.requests.cpu"
          value = "0m"
          type  = "string"
        },
        {
          name  = "csidriver.livenessprobe.resources.requests.cpu"
          value = "0m"
          type  = "string"
        }
      ],
      set_list = [],
      values   = []
    }
    default_helm_charts = {

pmaksfluentbit = {
  name       = "fluent-bit"
  chart      = "fluent-bit"
  repository = "https://artifactory.lbbw.sko.de/artifactory/api/helm/skywalker-helm-${local.af_environment_long}"
  namespace  = "logging"
  version    = "0.46.7"

  set = [
    # ── Image: pull from your Artifactory (same pattern as all other charts) ──
    {
      name  = "image.repository"
      value = "skywalker-docker-${local.af_environment_long}.artifactory.lbbw.sko.de/fluent/fluent-bit"
      type  = "string"
    },
    {
      name  = "imagePullSecrets[0].name"
      value = "artifactory-registry-secret"
      type  = "string"
    },

    # ── Run on ALL nodes (same toleration pattern as your other charts) ────────
    {
      name  = "tolerations[0].key"
      value = "CriticalAddonsOnly"
      type  = "string"
    },
    {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
      type  = "string"
    },
    {
      name  = "tolerations[0].operator"
      value = "Exists"
      type  = "string"
    },

    # ── Resource limits ───────────────────────────────────────────────────────
    {
      name  = "resources.requests.cpu"
      value = "100m"
      type  = "string"
    },
    {
      name  = "resources.requests.memory"
      value = "128Mi"
      type  = "string"
    },
    {
      name  = "resources.limits.cpu"
      value = "200m"
      type  = "string"
    },
    {
      name  = "resources.limits.memory"
      value = "256Mi"
      type  = "string"
    },

    # ── RBAC: Fluent Bit needs permission to read pod logs ────────────────────
    {
      name  = "rbac.create"
      value = "true"
      type  = "string"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
      type  = "string"
    }
  ],

  set_list = [],

  # ── Fluent Bit config: INPUT + FILTER + OUTPUT to Splunk HEC ─────────────
  values = [
    yamlencode({
      config = {
        service = <<-EOF
          [SERVICE]
              Flush         5
              Log_Level     info
              Daemon        off
              Parsers_File  /fluent-bit/etc/parsers.conf
              HTTP_Server   On
              HTTP_Listen   0.0.0.0
              HTTP_Port     2020
        EOF

        inputs = <<-EOF
          [INPUT]
              Name              tail
              Tag               kube.*
              Path              /var/log/containers/*.log
              multiline.parser  docker, cri
              DB                /var/log/flb_kube.db
              Mem_Buf_Limit     50MB
              Skip_Long_Lines   On
              Refresh_Interval  10
        EOF

        filters = <<-EOF
          [FILTER]
              Name                kubernetes
              Match               kube.*
              Kube_URL            https://kubernetes.default.svc:443
              Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
              Merge_Log           On
              Keep_Log            Off
              K8S-Logging.Parser  On
              K8S-Logging.Exclude On
              Annotations         Off
              Labels              On

          [FILTER]
              Name    record_modifier
              Match   *
              Record  source  azure-aks
              Record  env     ${var.infra_environment}
        EOF

        outputs = <<-EOF
          [OUTPUT]
              Name             splunk
              Match            *
              Host             ${var.splunk_hec_host}
              Port             ${var.splunk_hec_port}
              Splunk_Token     ${var.splunk_hec_token}
              Splunk_Send_Raw  On
              TLS              On
              TLS.Verify       Off
              compress         gzip
              Retry_Limit      5
        EOF
      }
    })
  ]
}
}
  }

  filtered_default_helm_charts = {
    for key, value in local.default_helm_charts :
    key => value
    if strcontains(var.selected_helm_chart, key)
  }
}
