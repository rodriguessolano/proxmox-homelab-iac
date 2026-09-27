resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = var.target_node
  vm_id     = var.vmid
  tags      = var.tags

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  network_device {
    bridge = var.network_bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address}/24"
        gateway = var.network_gateway
      }
    }

    # Nunca confiar no resolv.conf herdado do template — ver README.
    dns {
      servers = var.dns_servers
      domain  = var.dns_domain
    }

    user_account {
      username = var.ciuser
      password = var.cipassword
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }
}
