terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

# Sem bloco "provider" aqui de propósito — módulo reutilizável recebe o
# provider já configurado pelo root module que o chama (ver terraform/example).
