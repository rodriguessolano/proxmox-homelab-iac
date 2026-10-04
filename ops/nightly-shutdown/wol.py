#!/usr/bin/env python3
"""Envia um pacote Wake-on-LAN (magic packet) pra religar um host desligado.

Sem dependências externas (só biblioteca padrão) — funciona em qualquer
Linux/WSL/macOS com Python 3. Precisa estar na MESMA rede local do host
(broadcast UDP não atravessa a internet sem VPN/roteamento especial).

Uso:
    ./wol.py meu-host
    ./wol.py aa:bb:cc:dd:ee:ff                    # MAC direto
    ./wol.py aa:bb:cc:dd:ee:ff --broadcast 192.168.1.255
"""
import argparse
import socket
import sys

# Mapeia nomes conhecidos pro MAC real — edite aqui ou passe o MAC direto.
KNOWN_HOSTS = {
    "meu-host": "aa:bb:cc:dd:ee:ff",   # ip link show <nic> no host, trocar aqui
}

DEFAULT_BROADCAST = "192.168.1.255"
WOL_PORT = 9


def build_magic_packet(mac: str) -> bytes:
    mac_clean = mac.replace(":", "").replace("-", "")
    if len(mac_clean) != 12:
        raise ValueError(f"MAC inválido: {mac}")
    mac_bytes = bytes.fromhex(mac_clean)
    return b"\xff" * 6 + mac_bytes * 16


def send_wol(mac: str, broadcast_ip: str, port: int = WOL_PORT) -> None:
    packet = build_magic_packet(mac)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.sendto(packet, (broadcast_ip, port))


def main() -> None:
    parser = argparse.ArgumentParser(description="Envia magic packet Wake-on-LAN")
    parser.add_argument("target", help="nome conhecido ou MAC direto")
    parser.add_argument("--broadcast", default=DEFAULT_BROADCAST, help=f"IP de broadcast (default: {DEFAULT_BROADCAST})")
    parser.add_argument("--port", type=int, default=WOL_PORT, help="porta UDP (default: 9)")
    args = parser.parse_args()

    mac = KNOWN_HOSTS.get(args.target, args.target)

    try:
        send_wol(mac, args.broadcast, args.port)
    except ValueError as e:
        print(f"Erro: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Magic packet enviado pra {mac} via {args.broadcast}:{args.port}")


if __name__ == "__main__":
    main()
