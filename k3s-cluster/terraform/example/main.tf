# Exemplo de uso do módulo k3s-cluster — ajuste os valores abaixo para o
# seu ambiente. Nenhum valor aqui é sensível; segredos ficam só em
# terraform.tfvars (git-ignorado, ver terraform.tfvars.example).

module "k3s_cluster" {
  source = "../modules/k3s-cluster"

  target_node   = "pve"  # nome do seu node Proxmox
  template_vmid = 9000   # VMID do template criado em proxmox-templates/debian-12/

  worker_count   = 2
  node_memory_mb = 4096
  node_cores     = 2
  disk_size_gb   = 40

  network_prefix       = "10.0.10"
  network_gateway      = "10.0.10.1"
  master_ip            = "10.0.10.10"
  worker_ip_base_octet = 11

  k3s_token = var.k3s_token
}
