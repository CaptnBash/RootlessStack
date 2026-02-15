#!/bin/bash
set -euo pipefail # fail on error code, unset variables and pipeline fails on error code
source ~/variables.sh

curl $HC_UPGRADE_SYSTEM/start >/dev/null 2>&1 || true


apt update -qqq
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -qqq 

# clean up cached unused package files
apt autoremove -y
apt autoclean

# cleaning old logs
journalctl --vacuum-time=30d

# trigger docker image upgrade
machinectl shell -q dockie@ /usr/local/bin/docker-image-upgrade.sh

curl $HC_UPGRADE_SYSTEM >/dev/null 2>&1 || true

echo "Rebooting system..."
systemctl reboot
