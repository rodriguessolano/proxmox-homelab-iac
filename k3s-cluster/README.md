# Terraform: cluster k3s em Proxmox

Provisiona um cluster [k3s](https://k3s.io/) (1 control-plane + N workers)
em VMs Proxmox, a partir de um template cloud-init já pronto (ver
[`proxmox-templates/debian-12/`](../proxmox-templates/debian-12/)),
usando o provider [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox).

## Estrutura

```
terraform/
├── modules/
│   ├── proxmox-vm/      # VM genérica: clona template, cloud-init, DNS explícito
│   └── k3s-cluster/     # compõe N proxmox-vm + instala o k3s via SSH
└── example/             # root module de exemplo — é aqui que você roda `terraform apply`
```

## Por que separar em dois módulos

`proxmox-vm` não sabe nada sobre Kubernetes — é só "uma VM clonada de
template, com cloud-init e DNS corretos". `k3s-cluster` compõe várias
instâncias dele (1 master + N workers) e adiciona a lógica específica de
k3s por cima (`null_resource` + `remote-exec` instalando o k3s via SSH
depois que o cloud-init termina). Essa separação deixa `proxmox-vm`
reutilizável para qualquer outra VM do lab (banco de dados, servidor de
CI, etc.) sem carregar nada de k3s.

## Decisões de design

- **Instalação do k3s via Terraform** (`remote-exec` direto no *guest* via
  SSH, nunca no hypervisor) — um único `terraform apply` entrega o
  cluster pronto, sem depender de uma ferramenta de configuração separada
  rodando logo em seguida.
- **`cloud-init status --wait` antes de tentar qualquer coisa** — o
  primeiro boot de uma imagem cloud normalmente dispara atualização de
  pacotes, o que pode levar de 1 a 2 minutos antes do SSH responder de
  verdade; esperar evita falhas de "conexão recusada" no meio do
  provisionamento.
- **DNS sempre explícito via cloud-init** (nunca herdado do template) —
  ver a seção abaixo, é o achado mais importante deste módulo.
- **`sudo VAR=valor comando`** para instalar o k3s como um usuário não-root
  (`sudo K3S_TOKEN=... sh -`) — evita depender de login root direto por
  SSH.

## Achado: por que forçar DNS explícito

Um template de VM carrega qualquer configuração de rede que existia na
máquina/imagem original — incluindo um `resolv.conf` que pode apontar
para um servidor DNS que a VM clonada **não alcança** (por exemplo, o DNS
interno de uma VPN da máquina onde o template foi originalmente
preparado). O sintoma é sutil e engana: `curl -sfL <url> | sudo sh -` sem
nenhuma saída do `curl` ainda faz o `sh -` do lado direito do pipe sair
com código `0` (recebeu stdin vazio, "rodou" um script vazio com
sucesso) — então o `remote-exec` do Terraform reporta sucesso, mas nada
foi instalado de verdade.

A correção é sempre declarar servidores DNS explícitos no bloco
`initialization.dns` do provider `bpg/proxmox`, nunca confiar no que o
template já trouxer — é o que o módulo `proxmox-vm` faz por padrão
(`var.dns_servers`, default `1.1.1.1`/`8.8.8.8`).

## Uso

```bash
cd terraform/example
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com os dados do seu ambiente — NUNCA versione esse arquivo
terraform init
terraform plan
terraform apply
```

Ver `terraform/example/variables.tf` para a lista completa de variáveis e
`terraform/modules/k3s-cluster/variables.tf` para os defaults do
dimensionamento do cluster.
