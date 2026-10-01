#!/bin/bash
# Desligamento noturno do host Proxmox: para todas as VMs/LXCs de forma
# graciosa (ACPI shutdown, com timeout e fallback pra stop forçado),
# avisa no Telegram e só então desliga o host físico.
#
# Credenciais do bot (token + chat_id) ficam em /etc/homelab-shutdown.env
# (chmod 600, root), NUNCA neste repo. Formato:
#   TELEGRAM_BOT_TOKEN="123456789:ABC..."
#   TELEGRAM_CHAT_ID="123456789"
#
# Instalado via cron root em cada host (ver runbooks/nightly-shutdown.md).

set -euo pipefail

ENV_FILE="/etc/homelab-shutdown.env"
HOSTNAME_LABEL="$(hostname)"
GUEST_SHUTDOWN_TIMEOUT=120   # segundos de espera por VM/CT antes do stop forçado

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

send_telegram() {
  local msg="$1"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -s -m 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${msg}" \
      > /dev/null || logger -t nightly-shutdown "Falha ao enviar notificação Telegram"
  fi
}

log() {
  logger -t nightly-shutdown "$1"
  echo "$(date '+%F %T') $1"
}

log "Iniciando desligamento noturno de ${HOSTNAME_LABEL}"

# --- VMs (qm) ---
running_vms=$(qm list 2>/dev/null | awk 'NR>1 && $3=="running" {print $1}') || running_vms=""
for vmid in $running_vms; do
  log "Desligando VM ${vmid}..."
  qm shutdown "$vmid" --timeout "$GUEST_SHUTDOWN_TIMEOUT" || {
    log "VM ${vmid} não respondeu a tempo, forçando stop"
    qm stop "$vmid"
  }
done

# --- LXCs (pct) ---
running_cts=$(pct list 2>/dev/null | awk 'NR>1 && $2=="running" {print $1}') || running_cts=""
for ctid in $running_cts; do
  log "Desligando CT ${ctid}..."
  pct shutdown "$ctid" --timeout "$GUEST_SHUTDOWN_TIMEOUT" || {
    log "CT ${ctid} não respondeu a tempo, forçando stop"
    pct stop "$ctid"
  }
done

log "Todas as VMs/CTs de ${HOSTNAME_LABEL} paradas. Desligando o host em 30s."
send_telegram "🌙 ${HOSTNAME_LABEL}: VMs/CTs parados, desligando o host agora. Precisa ligar manualmente de manhã."

sleep 30
systemctl poweroff
