#!/bin/bash

# =======================
# KONFIGURASI DASAR
# =======================
WG_INTERFACE="wg0"
WG_PORT="51820"
WG_SERVER_PRIV_IP="10.66.66.1/24"
WG_CLIENT_PRIV_IP="10.66.66.2"
WG_PUBLIC_IP="217.15.166.107"
WG_DEV=$(ip route get 1.1.1.1 | grep -oP 'dev \K\S+')

# =======================
# INSTALASI
# =======================
apt update && apt install -y wireguard iproute2 iptables curl

# =======================
# GENERATE KEY
# =======================
mkdir -p /etc/wireguard/keys
wg genkey | tee /etc/wireguard/keys/server.key | wg pubkey > /etc/wireguard/keys/server.pub
wg genkey | tee /etc/wireguard/keys/client.key | wg pubkey > /etc/wireguard/keys/client.pub

SERVER_PRIV=$(cat /etc/wireguard/keys/server.key)
SERVER_PUB=$(cat /etc/wireguard/keys/server.pub)
CLIENT_PRIV=$(cat /etc/wireguard/keys/client.key)
CLIENT_PUB=$(cat /etc/wireguard/keys/client.pub)

# =======================
# BUAT KONFIGURASI SERVER
# =======================
cat > /etc/wireguard/${WG_INTERFACE}.conf <<EOF
[Interface]
Address = ${WG_SERVER_PRIV_IP}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}
PostUp = iptables -t nat -A POSTROUTING -s ${WG_CLIENT_PRIV_IP} -j SNAT --to-source ${WG_PUBLIC_IP}; ip route add ${WG_PUBLIC_IP} dev %i
PostDown = iptables -t nat -D POSTROUTING -s ${WG_CLIENT_PRIV_IP} -j SNAT --to-source ${WG_PUBLIC_IP}; ip route del ${WG_PUBLIC_IP} dev %i

[Peer]
PublicKey = ${CLIENT_PUB}
AllowedIPs = ${WG_CLIENT_PRIV_IP}/32
EOF

# =======================
# ENABLE IP FORWARDING
# =======================
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# =======================
# AKTIFKAN WIREGUARD
# =======================
systemctl enable wg-quick@${WG_INTERFACE}
systemctl start wg-quick@${WG_INTERFACE}

# =======================
# OUTPUT CONFIG CLIENT
# =======================
SERVER_REAL_IP=$(curl -s ifconfig.me)
cat > ~/wg-client.conf <<EOF

[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = ${WG_CLIENT_PRIV_IP}/32
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB}
Endpoint = ${SERVER_REAL_IP}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

EOF

echo "✅ WireGuard aktif dan siap."
echo "📄 File client tersimpan di ~/wg-client.conf"
echo "🌐 IP publik dialihkan ke klien: ${WG_PUBLIC_IP}"
