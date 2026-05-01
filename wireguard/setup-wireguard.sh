#!/bin/bash
set -eu

SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR" || exit 1

RED='\033[0;31m'
NC='\033[0m' # No Color

SERVER_PUBLIC_IP=$1

apt update -qq
apt install -y -qq wireguard

## Keypairs

SERVER_PRIVATE=$(wg genkey)
SERVER_PUBLIC=$(echo "$SERVER_PRIVATE" | wg pubkey)

NAS_PRIVATE=$(wg genkey)
NAS_PUBLIC=$(echo "$NAS_PRIVATE" | wg pubkey)

## Server config
install -m 600 server.conf /etc/wireguard/wg0.conf

sed -i "s|SERVER_PRIVATE_KEY|$SERVER_PRIVATE|g" /etc/wireguard/wg0.conf
sed -i "s|NAS_PUBLIC_KEY|$NAS_PUBLIC|g" /etc/wireguard/wg0.conf

## NAS config
cp client.conf client.conf.modified
sed -i "s|SERVER_PUBLIC_IP|$SERVER_PUBLIC_IP|g" client.conf.modified
sed -i "s|SERVER_PUBLIC_KEY|$SERVER_PUBLIC|g" client.conf.modified
sed -i "s|NAS_PRIVATE_KEY|$NAS_PRIVATE|g" client.conf.modified

## Enable and start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

## Output client config for NAS
clear
echo "WireGuard setup complete."
echo "Please run the following commands on the NAS:"
echo -e "${RED}apt update -qq && apt install -y -qq wireguard${NC}"
read -p "Press Enter to display the client configuration for your NAS..."

clear
echo  "Please copy the following client configuration to your NAS and start the WireGuard interface there:"
echo -e "\n${RED}/etc/wireguard/wg0.conf${NC}"
echo "----------------------------------------"
cat client.conf.modified
echo "----------------------------------------"

read -p "Press Enter to continue..."
clear
echo "Now run the commands:"
echo -e "${RED}systemctl enable wg-quick@wg0\nsystemctl start wg-quick@wg0${NC}\n\n"
echo "Configuration complete!"

## Wait for VPN connection
echo "Waiting for NAS to establish VPN connection (10.0.0.2)..."
echo "Press Ctrl+C to skip waiting."
echo ""

until ping -c1 -W2 10.0.0.2 &>/dev/null; do
    echo "  $(date '+%H:%M:%S') - NAS not connected yet, retrying..."
    sleep 5
done

echo "NAS connected! Tunnel details:"
wg show
