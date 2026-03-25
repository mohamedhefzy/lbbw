# *must* be declared within the module since it is no official provider
terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
    }
  }
}

resource "ansible_playbook" "deploy_oneagent_linux" {
  # referencing from module call (lz-template) point of view
  for_each = var.vm_linux_ips != null ? var.vm_linux_ips : {}

  playbook   = "../../azr-post-modules/vm-oneagent/playbook_oneagent_linux.yml"
  name       = each.value
  replayable = true
  verbosity  = 2

  extra_vars = {
    # relevant for ansible ssh
    ansible_username = var.ansible_username
    ansible_password = var.vm_passwords_linux[each.key]

    # relevant for downloading oneagent package from artifactory
    artifactory_user         = var.artifactory_user
    artifactory_token        = var.artifactory_token
    artifactory_url          = var.infra_environment == "e" ? "https://artifactory.lbbw.sko.de/artifactory/skywalker-packages-src/tools" : var.artifactory_url
    oneagent_use_artifactory = true

    # dynatrace instance api details
    oneagent_environment_url = var.is_old_tenant ? "https://${local.dynatrace_tenant[var.infra_environment]}.live.dynatrace.com" : "https://${local.dynatrace_tenant_new_tenant[var.infra_environment]}.live.dynatrace.com"
    oneagent_paas_token      = var.ONEAGENT_DYNATRACE_TOKEN
    oneagent_package_state   = var.TF_APPLY == "False" ? "absent" : "present"


  }
}

resource "ansible_playbook" "deploy_oneagent_windows" {
  # referencing from module call (lz-template) point of view
  for_each = var.vm_windows_ips != null ? var.vm_windows_ips : {}

  playbook   = "../../azr-post-modules/vm-oneagent/playbook_oneagent_windows.yml"
  name       = each.value
  replayable = true
  verbosity  = 2

  extra_vars = {
    # relevant for ansible winrm
    ansible_username = var.ansible_username
    ansible_password = var.vm_passwords_windows[each.key]

    # relevant for downloading oneagent package from artifactory
    artifactory_user         = var.artifactory_user
    artifactory_token        = var.artifactory_token
    artifactory_url          = var.infra_environment == "e" ? "https://artifactory.lbbw.sko.de/artifactory/skywalker-packages-src/tools" : var.artifactory_url

    # dynatrace instance api details
    oneagent_environment_url = var.is_old_tenant ? "https://${local.dynatrace_tenant[var.infra_environment]}.live.dynatrace.com" : "https://${local.dynatrace_tenant_new_tenant[var.infra_environment]}.live.dynatrace.com"
    oneagent_paas_token      = var.ONEAGENT_DYNATRACE_TOKEN
    oneagent_package_state   = var.TF_APPLY == "False" ? "absent" : "present"
  }
}
