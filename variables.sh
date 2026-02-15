# static variables
HOMEDIR=/home/dockie
BORG_CONFIG_FOLDER="$HOMEDIR/.config/borg"
BORG_PASSPHRASE_FOLDER="$BORG_CONFIG_FOLDER/passphrases"
BORG_KEYS_FOLDER="$BORG_CONFIG_FOLDER/keys"

# update this section based on your environment
APPS="caddy nextcloud nginx"
BACKUP_SERVER_IP="<server ip>"
BACKUP_SERVER_SSH_PORT=8022
BORG_REPO="borg@backupserver:/home/borg/backups"

HC_BACKUP_URL="https://hc-ping.com/<UUID>"

### CADDY ###
# EMAIL="internal" # use internal for self-signed certs
EMAIL="info@example.com" 

### NEXTCLOUD ###
NEXTCLOUD_DOMAIN="nextcloud.example.com"

### NGINX ###
NGINX_DOMAIN="www.example.com"
