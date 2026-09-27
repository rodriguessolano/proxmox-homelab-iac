variable "target_node" {
  description = "Nome do node Proxmox onde a VM roda"
  type        = string
}

variable "vmid" {
  description = "VMID da VM a criar"
  type        = number
}

variable "vm_name" {
  description = "Nome da VM no Proxmox"
  type        = string
}

variable "template_vmid" {
  description = "VMID do template cloud-init a clonar (ver proxmox-templates/debian-12/)"
  type        = number
}

variable "memory_mb" {
  type = number
}

variable "cores" {
  type    = number
  default = 2
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "storage" {
  description = "Datastore Proxmox onde o disco vive"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  description = "IP estático (sem CIDR) da VM"
  type        = string
}

variable "network_gateway" {
  type = string
}

variable "dns_servers" {
  description = "DNS forçado via cloud-init — nunca herdar o resolv.conf do template (ver README do módulo k3s-cluster: um template pode ter DNS de outra rede, inalcançável pela VM clonada, e isso quebra a resolução de nomes em silêncio)"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "dns_domain" {
  description = "Search domain forçado via cloud-init — vazio por padrão"
  type        = string
  default     = ""
}

variable "ciuser" {
  description = "Usuário de cloud-init"
  type        = string
  default     = "debian"
}

variable "cipassword" {
  description = "Senha de fallback do cloud-init — opcional (default null = login só por chave SSH)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "tags" {
  description = "Tags do Proxmox aplicadas à VM"
  type        = list(string)
  default     = []
}
