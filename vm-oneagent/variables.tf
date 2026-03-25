################################
# Global Variables
################################
variable "is_old_tenant" {
  description = ""
  type        = bool
}

variable "infra_environment" {
  description = "This variable defines the environment to be built. (Prod,Cert,Dev,Engineering)."
  type        = string
  validation {
    condition = contains(
      ["p", "c", "d", "e"],
      var.infra_environment
    )
    error_message = "infra_environment is not valid."
  }
}

################################
# Module Specific Variables
################################
variable "vm_linux_ips" {
  description = "Linux VM IPs"
  type        = map(string)
}

variable "vm_passwords_linux" {
  description = "Linux VM Password"
  type        = map(string)
  sensitive   = true
}

variable "vm_windows_ips" {
  description = "Windows VM IPs"
  type        = map(string)
}

variable "vm_passwords_windows" {
  description = "Windows VM Password"
  type        = map(string)
  sensitive   = true
}

variable "ansible_username" {
  description = "vm username for ansible to use"
  type        = string
}

variable "artifactory_user" {
  description = "artifactory user for downloading installer package"
  type        = string
}

variable "artifactory_token" {
  description = "artifactory Token for downloading installer package"
  type        = string
  sensitive   = true
}

variable "artifactory_url" {
  description = "Installation package name (URL) in Artifactory"
  type        = string
  default     = "https://artifactory.lbbw.sko.de/artifactory/skywalker-packages-prod/tools"
}

variable "TF_APPLY" {
  description = "Gets info if a Apply or Destroy is being run"
  type        = string
}

variable "ONEAGENT_DYNATRACE_TOKEN" {
  description = "dynatrace Token for downloading installer package"
  type        = string
  sensitive   = true
}
