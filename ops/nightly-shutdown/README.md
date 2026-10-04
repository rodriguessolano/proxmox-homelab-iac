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
- Pegar o MAC real do `proxmox` (está desligado agora) e preencher em
  `scripts/wol.py` → `KNOWN_HOSTS["proxmox"]`.
- Habilitar `Wake on LAN`/`Deep Sleep Control` na BIOS dos dois hosts
  (passo a passo documentado abaixo) — ainda não feito.

## Religando via Wake-on-LAN (`scripts/wol.py`)

Se habilitar WOL na BIOS (`Power Management` → `Deep Sleep Control: Disabled`
+ `Wake on LAN: LAN Only`), dá pra religar de qualquer PC/WSL na mesma rede:

```bash
python3 scripts/wol.py proxmox     # ou proxmox2
```

Sem dependências externas — usa só `socket` da stdlib. Os MACs ficam
hardcoded no topo do script (`KNOWN_HOSTS`), editar lá se a placa de rede
mudar. Pra usar do celular, qualquer app "Wake On Lan" da loja de
aplicativos funciona — só precisa configurar o MAC address manualmente
(mesmo valor do `KNOWN_HOSTS`) e estar na mesma rede Wi-Fi/LAN.

**Limitação importante:** broadcast UDP não atravessa a internet — só
funciona com o celular/PC já conectado na mesma rede local (Wi-Fi de casa,
por exemplo). Pra religar de fora de casa, precisaria de VPN até a rede
local primeiro (ex: Tailscale, que já está instalado no proxmox2).
