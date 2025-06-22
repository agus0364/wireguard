# Redirect semua koneksi masuk dari IP publik ke NAS (TCP + UDP)
iptables -t nat -A PREROUTING -d 217.15.165.61 -p tcp -j DNAT --to-destination 10.7.0.2
iptables -t nat -A PREROUTING -d 217.15.165.61 -p udp -j DNAT --to-destination 10.7.0.2

# Izinkan forward ke IP WireGuard NAS
iptables -A FORWARD -d 10.7.0.2 -p tcp -j ACCEPT
iptables -A FORWARD -d 10.7.0.2 -p udp -j ACCEPT
