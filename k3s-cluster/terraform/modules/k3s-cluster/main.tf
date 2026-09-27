# Compõe N instâncias do módulo proxmox-vm (1 master + var.worker_count
# workers), clonadas do mesmo template cloud-init, e usa null_resource +
# remote-exec (SSH direto ao GUEST, não ao hypervisor) para instalar o k3s
# depois que o cloud-init termina.

module "master" {
  source = "../proxmox-vm"

  target_node         = var.target_node
  vmid                = var.master_vmid
  vm_name             = "k3s-master-0"
  template_vmid       = var.template_vmid
  memory_mb           = var.node_memory_mb
  cores               = var.node_cores
  disk_size_gb        = var.disk_size_gb
  storage             = var.storage
  network_bridge      = var.network_bridge
  ip_address          = var.master_ip
  network_gateway     = var.network_gateway
  ciuser              = var.ciuser
  cipassword          = var.cipassword
  ssh_public_key_path = var.ssh_public_key_path
  tags                = concat(var.tags, ["k3s-master"])
}

module "worker" {
  source = "../proxmox-vm"
  count  = var.worker_count

  target_node         = var.target_node
  vmid                = var.worker_vmid_start + count.index
  vm_name             = "k3s-worker-${count.index}"
  template_vmid       = var.template_vmid
  memory_mb           = var.node_memory_mb
  cores               = var.node_cores
  disk_size_gb        = var.disk_size_gb
  storage             = var.storage
  network_bridge      = var.network_bridge
  ip_address          = "${var.network_prefix}.${var.worker_ip_base_octet + count.index}"
  network_gateway     = var.network_gateway
  ciuser              = var.ciuser
  cipassword          = var.cipassword
  ssh_public_key_path = var.ssh_public_key_path
  tags                = concat(var.tags, ["k3s-worker"])
}

# Instala o k3s server no master. "cloud-init status --wait" garante que a
# rede/usuário/chave SSH já estão prontos — o primeiro boot de uma imagem
# cloud normalmente dispara atualização de pacotes, que pode levar de 1 a 2
# minutos antes do SSH responder de fato.
resource "null_resource" "k3s_master" {
  depends_on = [module.master]

  triggers = {
    master_vmid = var.master_vmid
  }

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ciuser
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "curl -sfL https://get.k3s.io | sudo K3S_TOKEN=${var.k3s_token} sh -",
      "for i in $(seq 1 20); do sudo k3s kubectl get nodes >/dev/null 2>&1 && break; sleep 3; done",
    ]
  }
}

# Instala o k3s agent em cada worker, só depois do master estar respondendo.
resource "null_resource" "k3s_worker" {
  count      = var.worker_count
  depends_on = [module.worker, null_resource.k3s_master]

  triggers = {
    worker_vmid = var.worker_vmid_start + count.index
  }

  connection {
    type        = "ssh"
    host        = "${var.network_prefix}.${var.worker_ip_base_octet + count.index}"
    user        = var.ciuser
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "curl -sfL https://get.k3s.io | sudo K3S_URL=https://${var.master_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -",
    ]
  }
}
