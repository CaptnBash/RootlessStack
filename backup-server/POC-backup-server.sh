#!/bin/bash
# https://borgbackup.readthedocs.io/en/stable/usage/serve.html#ssh-configuration
# https://borgbackup.readthedocs.io/en/stable/quickstart.html#remote-repositories

apt update
apt install -y borgbackup

# --- configurable paths ---------------------------------
BORG_USER="borg"
BORG_HOME="/home/${BORG_USER}"
SSH_DIR="${BORG_HOME}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"
REPO_DIR="${BORG_HOME}/backups"
SSHD_CONF_DIR="/etc/ssh/sshd_config.d"
SSHD_CONF_BACKUP="${SSHD_CONF_DIR}/99-backup.conf"
# --------------------------------------------------------

# updating ssh server settings
mkdir -p "$SSHD_CONF_DIR"
echo "PubkeyAuthentication yes" > "$SSHD_CONF_BACKUP"
echo "ClientAliveInterval 10" >> "$SSHD_CONF_BACKUP"
echo "ClientAliveCountMax 30" >> "$SSHD_CONF_BACKUP"

# setting port
echo "PORT 8022" >> "$SSHD_CONF_BACKUP"

systemctl disable --now ssh.socket
systemctl restart ssh

systemctl enable ssh.socket

# creating borg user
useradd -m -s /bin/bash borg

# adding public key with restriction to authorized_keys for ssh authentication
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

clear
read -p "Client Public Key: " PUBLIC_KEY

BORG_PATH=$(which borg)
RESTRICTED_COMMAND="command=\"$BORG_PATH serve --restrict-to-path $REPO_DIR\",no-port-forwarding,no-X11-forwarding,no-pty,no-agent-forwarding"

echo "$RESTRICTED_COMMAND $PUBLIC_KEY" > "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

# setting up repo folder
mkdir -p "$REPO_DIR"

# make sure all files are owned by borg and not root
chown -R "$BORG_USER:$BORG_USER" "$BORG_HOME"
