# ── This is what links Terraform → Ansible on each VM ──

# LINUX / RHEL VMs
resource "azurerm_virtual_machine_extension" "run_ansible_linux" {
  for_each = var.linux_vm_ids

  name                 = "run-ansible-fluentbit"
  virtual_machine_id   = each.value
  publisher            = "Microsoft.Azure.Extensions"   # Linux publisher
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = jsonencode({
    commandToExecute = join(" && ", [
      # 1. Install Ansible
      "yum install -y ansible || apt-get install -y ansible",
      # 2. Install WinRM collection (not needed for Linux but harmless)
      "ansible-galaxy collection install ansible.windows || true",
      # 3. Write the playbook inline
      "mkdir -p /tmp/ansible",
      "cat > /tmp/ansible/playbook.yml << 'PLAYBOOK'\n${file("${path.module}/../../ansible/playbooks/install-fluentbit-linux.yml")}\nPLAYBOOK",
      "cat > /tmp/ansible/template.j2 << 'TMPL'\n${file("${path.module}/../../ansible/templates/fluent-bit-linux.conf.j2")}\nTMPL",
      # 4. Run playbook on localhost
      "ansible-playbook /tmp/ansible/playbook.yml -i localhost, --connection=local -e splunk_hec_host=${var.splunk_hec_host} -e splunk_hec_port=${var.splunk_hec_port} -e splunk_hec_token=${var.splunk_hec_token}"
    ])
  })

  tags = { tool = "fluent-bit", method = "ansible" }

  lifecycle {
    ignore_changes = [protected_settings]
  }
}

# WINDOWS VMs
resource "azurerm_virtual_machine_extension" "run_ansible_windows" {
  for_each = var.windows_vm_ids

  name                 = "run-ansible-fluentbit"
  virtual_machine_id   = each.value
  publisher            = "Microsoft.Compute"              # Windows publisher
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Install-PackageProvider -Name NuGet -Force; Install-Module -Name Ansible.Windows -Force; choco install ansible -y; ansible-playbook C:\\ansible\\playbook.yml -i localhost, --connection=local -e splunk_hec_host=${var.splunk_hec_host} -e splunk_hec_token=${var.splunk_hec_token} }\""
  })

  tags = { tool = "fluent-bit", method = "ansible" }

  lifecycle {
    ignore_changes = [protected_settings]
  }
}
