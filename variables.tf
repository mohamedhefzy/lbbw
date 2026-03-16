variable "app_environment" {
  description = "This variable defines the app environment of the specific application. Placeholder is 'x' if nothing is set."
  type        = string
}

variable "app_name" {
  description = "Name of the application per subscription"
  type        = string
}

variable "infra_environment" {
  description = "This variable defines the environment to be built. (Prod,Cert,Dev,Engineering)."
  type        = string
}

variable "lbbw_location" {
  description = "LBBW Location"
  type        = string
}

variable "selected_helm_chart" {
  description = "Gets info what folder/step has been selected in the pipeline"
  type        = string
}

variable "artifactory_username" {
  description = "The artifatory username"
  type        = string
}

variable "artifactory_password" {
  description = "The artifactory passowrd"
  type        = string
}

variable "private_dns_rg_name" {
  description = "Private DNS Zone Resource Group Name"
  type        = string
}

variable "private_dns_zone_name" {
  description = "Private DNS Zone Name"
  type        = string
}

variable "cluster_config" {
  description = "Kubernetes Cluster Konfigurationsdetails"
  type = object({
    host                   = string
    username               = string
    password               = string
    client_certificate     = string
    client_key             = string
    cluster_ca_certificate = string
  })
}

variable "user_assigned_identity_default_mid_client_id" {
  description = "The default user assigned identity client_id of aks"
  type        = string
}

variable "helm" {
  description = "Config of the helm resources"
  type = object({
    vnet_subnet_key = string
    helm_release_configs = map(object({
      name       = string
      chart      = string
      repository = string
      namespace  = string
      version    = string
      set = list(object({
        name  = string
        value = string
        type  = string
      }))
      set_list = list(object({
        name  = string
        value = list(string)
      }))
      values = list(string)
    }))
  })
}
variable "splunk_hec_host" {
  description = "Splunk HEC hostname (without https://)"
  type        = string
}

variable "splunk_hec_port" {
  description = "Splunk HEC port"
  type        = number
  default     = 8088
}

variable "splunk_hec_token" {
  description = "Splunk HEC authentication token"
  type        = string
  sensitive   = true
}