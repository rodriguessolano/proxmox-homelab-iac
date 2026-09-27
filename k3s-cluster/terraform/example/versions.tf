terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  insecure = true # certificado autoassinado do Proxmox

  # Prefira um token de API escopado em vez de usuário/senha root — ver
  # https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication
  api_token = var.pm_api_token
}
