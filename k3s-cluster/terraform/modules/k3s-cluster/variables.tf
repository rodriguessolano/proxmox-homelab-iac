variable "target_node" {
  description = "Node Proxmox onde o cluster roda"
  type        = string
}

variable "template_vmid" {
  description = "VMID do template cloud-init já validado a clonar (ver proxmox-templates/debian-12/)"
  type        = number
}

variable "master_vmid" {
  type    = number
  default = 800
}

variable "worker_vmid_start" {
  description = "Primeiro VMID dos workers (worker-0 = este valor, worker-1 = +1, ...)"
  type        = number
  default     = 801
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "node_memory_mb" {
  description = "RAM por nó em MiB"
  type        = number
  default     = 4096
}

variable "node_cores" {
  type    = number
  default = 2
}

variable "disk_size_gb" {
  type    = number
  default = 40
}

variable "storage" {
  type    = string
  default = "local-lvm"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_gateway" {
  description = "Gateway da rede onde o cluster vive"
  type        = string
}

variable "master_ip" {
  description = "IP fixo do master"
  type        = string
}

variable "worker_ip_base_octet" {
  description = "Último octeto do primeiro worker (worker-0 = este valor, worker-1 = +1, ...) — assume que master e workers estão no mesmo /24"
  type        = number
}

variable "network_prefix" {
  description = "Os três primeiros octetos da rede dos workers, ex. \"10.0.10\" — combinado com worker_ip_base_octet forma o IP de cada worker"
  type        = string
}

variable "ciuser" {
  type    = string
  default = "debian"
}

variable "cipassword" {
  description = "Senha de fallback do cloud-init — opcional, default null (login só por chave SSH)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Chave privada usada pelo remote-exec para instalar o k3s via SSH nos nós recém-criados"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "k3s_token" {
  description = "Token de bootstrap do cluster k3s — sem default, nunca versionar o valor real"
  type        = string
  sensitive   = true
}

variable "tags" {
  type    = list(string)
  default = ["k3s", "homelab"]
}
