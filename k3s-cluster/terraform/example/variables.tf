variable "pm_api_url" {
  description = "Endpoint da API do seu Proxmox, ex. https://<SEU_HOST>:8006/"
  type        = string
}

variable "pm_api_token" {
  description = "Token de API do Proxmox, formato user@realm!token-name=secret"
  type        = string
  sensitive   = true
}

variable "k3s_token" {
  description = "Token de bootstrap do cluster k3s — gere um valor aleatório forte, ex. `openssl rand -hex 32`"
  type        = string
  sensitive   = true
}
