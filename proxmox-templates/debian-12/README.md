# Template Debian 12 (cloud-init) para Proxmox

Runbook manual para construir um template Debian 12 pronto para clonagem
via Terraform (cloud-init + qemu-guest-agent já configurados). É a base
que o [módulo Terraform do cluster k3s](../../k3s-cluster/) espera
encontrar.

> Valores como VMID, storage e faixa de IP abaixo são **exemplos** — ajuste
> para o seu ambiente. Nenhum comando aqui precisa de credencial alguma
> além de acesso root ao seu próprio host Proxmox.

## Pré-requisitos

- Acesso root (SSH ou console) ao host Proxmox.
- `libguestfs-tools` instalado no host, para customizar a imagem antes do
  primeiro boot (`apt install libguestfs-tools`).

## 1. Baixar a imagem cloud

```bash
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2 \
  -O debian-12-cloud.qcow2
```

## 2. Customizar a imagem antes do primeiro boot

Instala o `qemu-guest-agent` (necessário para o Terraform saber o IP e o
estado da VM) e o `chrony` (sincronização de horário), e prepara a imagem
para ser clonada várias vezes sem colisão de identidade (machine-id e
host keys SSH regenerados no primeiro boot de cada clone).

```bash
virt-customize --add debian-12-cloud.qcow2 \
  --install qemu-guest-agent,chrony \
  --run-command 'systemctl enable qemu-guest-agent chrony' \
  --timezone UTC \
  --run-command 'rm -f /etc/ssh/ssh_host_*' \
  --run-command 'echo -e "[Unit]\nDescription=Regenerate SSH host keys\nBefore=ssh.service\nConditionPathExists=!/etc/ssh/ssh_host_rsa_key\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/ssh-keygen -A\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/regen-ssh-hostkeys.service' \
  --run-command 'systemctl enable regen-ssh-hostkeys.service' \
  --run-command 'truncate -s 0 /etc/machine-id' \
  --run-command 'rm -f /var/lib/dbus/machine-id && ln -s /etc/machine-id /var/lib/dbus/machine-id'
```

### Login: chave SSH (recomendado) vs. senha (só laboratório)

O jeito mais simples de testar é habilitar login root por senha — **não
use isso fora de um laboratório isolado**:

```bash
# Convniência de laboratório — NÃO faça isso em produção.
virt-customize --add debian-12-cloud.qcow2 \
  --run-command 'sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config' \
  --run-command 'sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config'
```

A alternativa correta é não tocar em `PermitRootLogin`/`PasswordAuthentication`
(ficam no padrão restritivo da imagem cloud) e injetar só a chave pública
via cloud-init na hora de clonar — é exatamente o que o
[módulo `proxmox-vm`](../../k3s-cluster/terraform/modules/proxmox-vm/)
faz por padrão (`cipassword` é opcional, default `null`).

## 3. Criar a VM a partir da imagem

```bash
VMID=9000                      # exemplo — use um VMID livre no seu host
STORAGE=local-lvm              # exemplo — seu datastore de VMs

qm create $VMID --name debian-12-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk $VMID "$(pwd)/debian-12-cloud.qcow2" $STORAGE
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --ide2 $STORAGE:cloudinit,media=cdrom
qm set $VMID --agent enabled=1
qm set $VMID --ipconfig0 ip=dhcp   # ou IP estático — ver README do módulo Terraform
qm resize $VMID scsi0 +8G
```

## 4. Testar antes de converter em template

```bash
qm start $VMID
qm terminal $VMID     # Ctrl+O para sair do console serial
```

Confirme que a VM sobe, pega IP (`ip a`) e que o `qemu-guest-agent` está
rodando (`systemctl status qemu-guest-agent`).

## 5. Converter em template

```bash
qm shutdown $VMID
qm template $VMID
```

A partir daqui, `$VMID` pode ser referenciado como `template_vmid` no
[módulo `proxmox-vm`](../../k3s-cluster/terraform/modules/proxmox-vm/).
