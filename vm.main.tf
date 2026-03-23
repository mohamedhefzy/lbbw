data "azurerm_client_config" "current" {
  # Returns the values of the currently logged in user
  # client_id         - is set to the Azure Client ID (Application Object ID).
  # tenant_id         - is set to the Azure Tenant ID.
  # subscription_id   - is set to the Azure Subscription ID.
  # object_id         - is set to the Azure Object ID.
}

data "template_file" "winrm_config" {
  for_each = var.vm.windows != null ? azurerm_windows_virtual_machine.windows-vm : {}
  template = file("../../azr-modules/vm/configureWinRM.ps1")
  vars = {
    resource_group_name    = "${each.value.resource_group_name}"
    vm_name                = "${each.value.name}"
    lbbw_location          = "${var.lbbw_location}"
    prefix_app_name        = "${local.prefix_app_name}"
    infra_environment_long = "${local.infra_environment_long}"
  }
}

resource "azurerm_resource_group" "rg-vm" {
  name     = "${local.name_prefix}-rg-${local.prefix_app_name}-vm"
  location = var.location

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

resource "null_resource" "script-permission" {
  provisioner "local-exec" {
    command = "chmod 777 ../../azr-modules/vm/registerFeature.sh"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "register-feature" {
  provisioner "local-exec" {
    command = "../../azr-modules/vm/registerFeature.sh"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [null_resource.script-permission]
}

resource "azurerm_availability_set" "availability-set" {
  for_each                     = var.vm.availability_sets != null ? var.vm.availability_sets : {}
  name                         = "${local.name_prefix}-avail-${local.prefix_app_name}-${each.key}"
  resource_group_name          = azurerm_resource_group.rg-vm.name
  location                     = azurerm_resource_group.rg-vm.location
  platform_fault_domain_count  = each.value.platform_fault_domain_count
  platform_update_domain_count = each.value.platform_update_domain_count

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

resource "random_integer" "zone" {
  min = 1
  max = 3
}

resource "azurerm_disk_encryption_set" "disc-encryption-set" {
  count = contains(["3", "4"], var.sbk) ? 1 : 0

  name                = "${local.name_prefix}-des-${local.prefix_app_name}"
  resource_group_name = azurerm_resource_group.rg-vm.name
  location            = var.location
  key_vault_key_id    = var.keyvault_encryption_key_id

  identity {
    type         = "UserAssigned"
    identity_ids = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.name_prefix}-rg-${local.prefix_app_name}-infra/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.name_prefix}-mid-${local.prefix_app_name}-infra"]
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

####################################################################
############################ L I N U X #############################
####################################################################

resource "azurerm_linux_virtual_machine" "linux-vm" {
  for_each                        = var.vm.linux != null ? var.vm.linux : {}
  name                            = "${var.lbbw_location}${var.infra_environment}${var.app_environment}${var.app_name}${each.key}"
  resource_group_name             = azurerm_resource_group.rg-vm.name
  location                        = var.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  admin_password                  = random_password.vm_passwords_linux[each.key].result
  disable_password_authentication = each.value.disable_password_authentication
  vtpm_enabled                    = each.value.vtpm_enabled
  zone                            = var.vm.availability_sets == null ? (each.value.zone == null ? tostring(random_integer.zone.result) : each.value.zone) : null
  availability_set_id             = var.vm.availability_sets != null ? azurerm_availability_set.availability-set[each.value.availability_set_name].id : null
  encryption_at_host_enabled      = true
  network_interface_ids = [
    azurerm_network_interface.nic[each.value.nic_id_key].id
  ]

  os_disk {
    disk_size_gb           = each.value.os_disk.disk_size_gb
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type == null ? local.get_storage_account_type : each.value.os_disk.storage_account_type
    disk_encryption_set_id = contains(["3", "4"], var.sbk) ? azurerm_disk_encryption_set.disc-encryption-set[0].id : null
  }

  source_image_id     = var.is_old_tenant ? "/subscriptions/${local.image_subscription_id[var.infra_environment]}/resourceGroups/euaho-${var.infra_environment}-rg-vmif-gal/providers/Microsoft.Compute/galleries/euaho${var.infra_environment}galvmif/images/${each.value.custom_image_reference.image_name}/versions/${each.value.custom_image_reference.version == null ? local.IMAGE_VERSIONS[each.value.custom_image_reference.image_name] : each.value.custom_image_reference.version}" : "/subscriptions/${local.image_subscription_id_new_tenant[var.infra_environment]}/images/${each.value.custom_image_reference.image_name}/versions/${each.value.custom_image_reference.version == null ? local.IMAGE_VERSIONS[each.value.custom_image_reference.image_name] : each.value.custom_image_reference.version}"
  secure_boot_enabled = true

  # Fixes issue that causes root LVM to be only 2G in size
  # TODO: Find cause and remove custom_data eventually
  custom_data = "I2Nsb3VkLWNvbmZpZwpydW5jbWQ6CiAgLSBzdWRvIGx2ZXh0ZW5kIC1sICsxMDAlRlJFRSAvZGV2L3Jvb3R2Zy9yb290bHYKICAtIHN1ZG8geGZzX2dyb3dmcyAvCiAgLSBkZiAtaA=="
  #Base64 string of the folowing command:
  # #cloud-config
  # runcmd:
  #  - sudo lvextend -l +100%FREE /dev/rootvg/rootlv
  #  - sudo xfs_growfs /
  #  - df -h' | base64

  ### This dynamic block is only set if the selected image is a NON-marketplace image ###
  dynamic "plan" {
    for_each = local.IMAGE_PLANS[each.value.custom_image_reference.image_name] == null ? [] : [1]
    content {
      name      = local.IMAGE_PLANS[each.value.custom_image_reference.image_name].name
      publisher = local.IMAGE_PLANS[each.value.custom_image_reference.image_name].publisher
      product   = local.IMAGE_PLANS[each.value.custom_image_reference.image_name].product
    }
  }

  identity {
    type         = length(var.mssql_user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = length(var.mssql_user_assigned_identity_ids) > 0 ? values(var.mssql_user_assigned_identity_ids) : null
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }

  depends_on = [azurerm_marketplace_agreement.ama-linux]
}

resource "random_password" "vm_passwords_linux" {
  for_each         = var.vm.linux != null ? var.vm.linux : {}
  length           = 24
  special          = true
  override_special = "!#$%*()-_=+[]{}:?"
}

resource "azurerm_key_vault_secret" "password_entries_linux" {
  for_each     = var.vm.linux != null ? var.vm.linux : {}
  name         = "kvs-${local.prefix_app_name}-${each.key}"
  value        = random_password.vm_passwords_linux[each.key].result
  key_vault_id = var.platform_keyvault_id

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

resource "azurerm_virtual_machine_extension" "linux_aad_login" {
  for_each             = var.vm.is_aad_active ? azurerm_linux_virtual_machine.linux-vm : {}
  name                 = "AADLogin"
  virtual_machine_id   = each.value.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

### The marketplace agreement is only needed IF a image is pulled from the official marketplace and NOT the VMIF image factory ###
resource "azurerm_marketplace_agreement" "ama-linux" {
  for_each  = local.linux_agreements
  publisher = local.IMAGE_PLANS[each.key].publisher
  offer     = local.IMAGE_PLANS[each.key].product
  plan      = local.IMAGE_PLANS[each.key].name
}

####################################################################
########################## W I N D O W S ###########################
####################################################################

resource "azurerm_windows_virtual_machine" "windows-vm" {
  for_each                   = var.vm.windows != null ? var.vm.windows : {}
  name                       = "${var.lbbw_location}${var.infra_environment}${var.app_environment}${var.app_name}${each.key}"
  resource_group_name        = azurerm_resource_group.rg-vm.name
  location                   = var.location
  size                       = each.value.size
  admin_username             = each.value.admin_username
  admin_password             = random_password.vm_passwords_windows[each.key].result
  vtpm_enabled               = each.value.vtpm_enabled
  zone                       = var.vm.availability_sets == null ? (each.value.zone == null ? tostring(random_integer.zone.result) : each.value.zone) : null
  availability_set_id        = var.vm.availability_sets != null ? azurerm_availability_set.availability-set[each.value.availability_set_name].id : null
  encryption_at_host_enabled = true
  network_interface_ids = [
    azurerm_network_interface.nic[each.value.nic_id_key].id
  ]

  os_disk {
    disk_size_gb           = each.value.os_disk.disk_size_gb
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type == null ? local.get_storage_account_type : each.value.os_disk.storage_account_type
    disk_encryption_set_id = contains(["3", "4"], var.sbk) ? azurerm_disk_encryption_set.disc-encryption-set[0].id : null
  }

  source_image_id     = var.is_old_tenant ? "/subscriptions/${local.image_subscription_id[var.infra_environment]}/resourceGroups/euaho-${var.infra_environment}-rg-vmif-gal/providers/Microsoft.Compute/galleries/euaho${var.infra_environment}galvmif/images/${each.value.custom_image_reference.image_name}/versions/${each.value.custom_image_reference.version == null ? local.IMAGE_VERSIONS[each.value.custom_image_reference.image_name] : each.value.custom_image_reference.version}" : "/subscriptions/${local.image_subscription_id_new_tenant[var.infra_environment]}/images/${each.value.custom_image_reference.image_name}/versions/${each.value.custom_image_reference.version == null ? local.IMAGE_VERSIONS[each.value.custom_image_reference.image_name] : each.value.custom_image_reference.version}"
  secure_boot_enabled = true

  ### This dynamic block is only set if the selected image is a NON-marketplace image ###
  dynamic "plan" {
    for_each = local.IMAGE_PLANS[each.value.custom_image_reference.image_name] == null ? [] : [1]
    content {
      name      = local.IMAGE_PLANS[each.value.custom_image_reference.image_name].name
      publisher = local.IMAGE_PLANS[each.value.custom_image_reference.image_name].publisher
      product   = local.IMAGE_PLANS[each.value.custom_image_reference.image_name].product
    }
  }

  ### Maybe this is usable instaed of using the configureWinRM.ps1 script? dunno - test sometime ###
  # winrm_listener {
  #   protocol = "Https"
  # }

  identity {
    type         = length(var.mssql_user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = length(var.mssql_user_assigned_identity_ids) > 0 ? values(var.mssql_user_assigned_identity_ids) : null
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }

  depends_on = [azurerm_marketplace_agreement.ama-windows]
}

resource "random_password" "vm_passwords_windows" {
  for_each         = var.vm.windows != null ? var.vm.windows : {}
  length           = 24
  special          = true
  override_special = "!#$%*()-_=+[]{}:?"
}

resource "azurerm_key_vault_secret" "password_entries_windows" {
  for_each     = var.vm.windows != null ? var.vm.windows : {}
  name         = "kvs-${local.prefix_app_name}-${each.key}"
  value        = random_password.vm_passwords_windows[each.key].result
  key_vault_id = var.platform_keyvault_id

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

### Aktuell ein Workaround bis winrm über das Golden Image der VMIF richtig konfiguriert wird.
### Zusätzlich wird danach ein Script ausgeführt, in dem die Disks initialisiert werden.
resource "azurerm_virtual_machine_extension" "winrm_custom_script" {
  for_each             = var.vm.windows != null ? azurerm_windows_virtual_machine.windows-vm : {}
  name                 = "customScriptExtension_InitConfig"
  virtual_machine_id   = each.value.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = <<SETTINGS
  {    
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.winrm_config[each.key].rendered)}')) | Out-File -filepath configureWinRM.ps1\" && powershell -ExecutionPolicy Unrestricted -File configureWinRM.ps1 -RESOURCE_GROUP_NAME ${data.template_file.winrm_config[each.key].vars.resource_group_name} -VM_NAME ${data.template_file.winrm_config[each.key].vars.vm_name} -LBBW_LOCATION ${data.template_file.winrm_config[each.key].vars.lbbw_location} -PREFIX_APP_NAME ${data.template_file.winrm_config[each.key].vars.prefix_app_name} -INFRA_ENVIRONMENT_LONG ${data.template_file.winrm_config[each.key].vars.infra_environment_long}"
  }
  SETTINGS

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

resource "time_sleep" "wait_180_seconds_for_restart_before_aad_plugin" {
  create_duration = "180s"

  depends_on = [azurerm_virtual_machine_extension.winrm_custom_script]
}

resource "azurerm_virtual_machine_extension" "windows_aad_login" {
  for_each             = var.vm.is_aad_active ? azurerm_windows_virtual_machine.windows-vm : {}
  name                 = "AADLogin"
  virtual_machine_id   = each.value.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "2.2"

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
  depends_on = [time_sleep.wait_180_seconds_for_restart_before_aad_plugin]
}

### Aktuell FW technisch nicht freischaltbar, da wir die Update Server von Microsoft nicht erreichen - winrm nutzen
# resource "azurerm_virtual_machine_extension" "windows_openssh" {
#   for_each             = azurerm_windows_virtual_machine.windows-vm
#   name                 = "WindowsOpenSSH"
#   virtual_machine_id   = azurerm_windows_virtual_machine.windows-vm[each.key].id
#   publisher            = "Microsoft.Azure.OpenSSH"
#   type                 = "WindowsOpenSSH"
#   type_handler_version = "3.0"
# }

### The marketplace agreement is only needed IF a image is pulled from the official marketplace and NOT the VMIF image factory ###
resource "azurerm_marketplace_agreement" "ama-windows" {
  for_each  = local.windows_agreements
  publisher = local.IMAGE_PLANS[each.key].publisher
  offer     = local.IMAGE_PLANS[each.key].product
  plan      = local.IMAGE_PLANS[each.key].name
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.vm.network_interfaces
  name                = "${local.name_prefix}-nic-${local.prefix_app_name}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-vm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[each.value.subnet_key_name]
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

#####################################
########## Backup ###################
#####################################

resource "azurerm_resource_group" "rg-disk-snapshots" {
  name     = "${local.name_prefix}-rg-${local.prefix_app_name}-vm-disk-snapshots"
  location = var.location

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
}

resource "null_resource" "delete-recovery-snapshots" {
  count = var.infra_environment == "e" ? 1 : 0 # We don't just want to delete all Snapshots on Productive Stages

  triggers = {
    rg_disk_snapshots = azurerm_resource_group.rg-disk-snapshots.name
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "chmod +x ../../azr-modules/gen_scripts/delete_recovery_snapshots.sh && ../../azr-modules/gen_scripts/delete_recovery_snapshots.sh ${self.triggers.rg_disk_snapshots}"
    on_failure = "continue"
  }

  depends_on = [
    azurerm_disk_encryption_set.disc-encryption-set,
    azurerm_resource_group.rg-disk-snapshots
  ]
}

resource "azurerm_role_assignment" "disk-backup-role-windows" {
  for_each             = azurerm_managed_disk.managed-disk-windows
  scope                = each.value.id
  role_definition_name = "Disk Backup Reader"
  principal_id         = var.bvault_principal_id
}

resource "azurerm_role_assignment" "disk-backup-role-linux" {
  for_each             = azurerm_managed_disk.managed-disk-linux
  scope                = each.value.id
  role_definition_name = "Disk Backup Reader"
  principal_id         = var.bvault_principal_id
}


resource "azurerm_role_assignment" "disk-backup-role-snapshots" {
  scope                = azurerm_resource_group.rg-disk-snapshots.id
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = var.bvault_principal_id
}

resource "azurerm_data_protection_backup_instance_disk" "backup-instance-windows-disks" {
  for_each                     = local.windows_managed_disks_flatten
  name                         = "dpbid-ws-${each.key}"
  location                     = azurerm_resource_group.rg-vm.location
  vault_id                     = var.bvault_id
  disk_id                      = azurerm_managed_disk.managed-disk-windows[each.key].id
  snapshot_resource_group_name = azurerm_resource_group.rg-disk-snapshots.name
  backup_policy_id             = var.bvault_disk_policy_id
}

resource "azurerm_data_protection_backup_instance_disk" "backup-instance-linux-disks" {
  for_each                     = local.linux_managed_disks_flatten
  name                         = "dpbid-lx-${each.key}"
  location                     = azurerm_resource_group.rg-vm.location
  vault_id                     = var.bvault_id
  disk_id                      = azurerm_managed_disk.managed-disk-linux[each.key].id
  snapshot_resource_group_name = azurerm_resource_group.rg-disk-snapshots.name
  backup_policy_id             = var.bvault_disk_policy_id
}

resource "azurerm_backup_protected_vm" "protected-windows-vm" {
  for_each            = var.vm.windows != null ? var.vm.windows : {}
  resource_group_name = var.rsvault_rg_name
  recovery_vault_name = var.rsvault_name

  source_vm_id     = azurerm_windows_virtual_machine.windows-vm[each.key].id
  backup_policy_id = var.rsvault_vm_policy_id

  depends_on = [azurerm_windows_virtual_machine.windows-vm]
}

resource "azurerm_backup_protected_vm" "protected-linux-vm" {
  for_each            = var.vm.linux != null ? var.vm.linux : {}
  resource_group_name = var.rsvault_rg_name
  recovery_vault_name = var.rsvault_name

  source_vm_id     = azurerm_linux_virtual_machine.linux-vm[each.key].id
  backup_policy_id = var.rsvault_vm_policy_id

  depends_on = [azurerm_linux_virtual_machine.linux-vm]
}

##############################
###### Managed Disk ##########
##############################
resource "azurerm_managed_disk" "managed-disk-windows" {
  for_each               = local.windows_managed_disks_flatten
  name                   = "${local.name_prefix}-md-${each.key}-${local.prefix_app_name}"
  resource_group_name    = azurerm_resource_group.rg-vm.name
  location               = var.location
  storage_account_type   = each.value.storage_account_type == null ? local.get_storage_account_type : each.value.storage_account_type
  tier                   = each.value.tier
  create_option          = "Empty"
  disk_size_gb           = each.value.disk_size_gb
  zone                   = var.vm.availability_sets == null ? (each.value.zone == null ? tostring(random_integer.zone.result) : each.value.zone) : null
  disk_encryption_set_id = contains(["3", "4"], var.sbk) ? azurerm_disk_encryption_set.disc-encryption-set[0].id : null

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
  depends_on = [azurerm_disk_encryption_set.disc-encryption-set]
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk-attachement_windows" {
  for_each           = local.windows_managed_disks_flatten
  managed_disk_id    = azurerm_managed_disk.managed-disk-windows[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.windows-vm[each.value.windows_key].id
  lun                = tostring(local.windows_indices[each.key])
  caching            = "None"
}

resource "azurerm_managed_disk" "managed-disk-linux" {
  for_each               = local.linux_managed_disks_flatten
  name                   = "${local.name_prefix}-md-${each.key}-${local.prefix_app_name}"
  resource_group_name    = azurerm_resource_group.rg-vm.name
  location               = var.location
  storage_account_type   = local.get_storage_account_type
  tier                   = each.value.tier
  create_option          = "Empty"
  disk_size_gb           = each.value.disk_size_gb
  zone                   = var.vm.availability_sets == null ? (each.value.zone == null ? tostring(random_integer.zone.result) : each.value.zone) : null
  disk_encryption_set_id = contains(["3", "4"], var.sbk) ? azurerm_disk_encryption_set.disc-encryption-set[0].id : null

  tags = var.tags

  lifecycle {
    ignore_changes = [            # If not explicitely highlighted, tags are applied and inherited by Azure Policy
      tags["AppName"],
      tags["Availability"],
      tags["Confidentiality"],
      tags["CreationDateTime"],   # This tag is maintained by Terraform and must only be created once at creating time
      tags["Creator"],            # This tag is maintained by Terraform and must only be created once at creating time
      tags["Environment"],
      tags["Integrity"],
      tags["ITAB"],
      tags["Owner"],
      tags["PlatformId"],
      # tags["Source"],           # This tag is maintained by Terraform
      tags["SubscriptionType"]
    ]
  }
  depends_on = [azurerm_disk_encryption_set.disc-encryption-set]
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk-attachement_linux" {
  for_each           = local.linux_managed_disks_flatten
  managed_disk_id    = azurerm_managed_disk.managed-disk-linux[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux-vm[each.value.linux_key].id
  lun                = tostring(local.linux_indices[each.key])
  caching            = "None"
}

resource "azurerm_role_assignment" "keyvault_access_linux" {
  for_each             = var.vm.linux != null ? var.vm.linux : {}
  scope                = var.keyvault_keyvault_ids["app"]
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.linux-vm[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "keyvault_access_windows" {
  for_each             = var.vm.windows != null ? var.vm.windows : {}
  scope                = var.keyvault_keyvault_ids["app"]
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.windows-vm[each.key].identity[0].principal_id
}
