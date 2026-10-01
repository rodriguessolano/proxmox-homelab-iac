# Desligamento noturno dos hosts Proxmox

Desliga os dois hosts físicos (não só as VMs) todas as noites, pra economizar
energia. **Importante:** como é o host inteiro que desliga, ele só volta com
alguém apertando o botão físico (ou Wake-on-LAN/IPMI, se configurado no
futuro) — não tem "religar por agendamento" via software puro.

## O que o script faz (`scripts/nightly-shutdown.sh`)

1. Lista VMs (`qm list`) e LXCs (`pct list`) em execução no host.
2. Pede desligamento gracioso de cada um (`qm shutdown`/`pct shutdown`,
   timeout de 120s) — só força stop (`qm stop`/`pct stop`) se não responder.
3. Envia notificação no Telegram.
4. Desliga o host (`systemctl poweroff`).

Roda **localmente em cada host** (não depende de nada externo pra decidir
desligar) — cada Proxmox cuida de si mesmo.

## Credenciais do Telegram

Ficam em `/etc/homelab-shutdown.env` em cada host (`chmod 600`, root),
**nunca neste repo**:

```
TELEGRAM_BOT_TOKEN="<token do @BotFather>"
TELEGRAM_CHAT_ID="<seu chat_id>"
```

## Instalação (em cada host)

```bash
scp scripts/nightly-shutdown.sh root@<host>:/usr/local/sbin/nightly-shutdown.sh
ssh root@<host> "chmod 700 /usr/local/sbin/nightly-shutdown.sh"

# criar /etc/homelab-shutdown.env com as credenciais (ver acima)

# cron root, todo dia às 23:30
ssh root@<host> 'crontab -l 2>/dev/null; echo "30 23 * * * /usr/local/sbin/nightly-shutdown.sh >> /var/log/nightly-shutdown.log 2>&1"' | ssh root@<host> 'crontab -'
```

## Religando de manhã

Sem Wake-on-LAN/IPMI configurado, é botão físico mesmo. Se os dois hosts
tiverem placa-mãe com suporte, dá pra configurar WOL depois (item em aberto,
não feito ainda).

## Pendente

- Testar uma noite real antes de confiar 100% (primeira execução, ver se o
  Telegram chega e se os hosts desligam limpo).
- Considerar Wake-on-LAN pra religar via rede em vez de botão físico.
