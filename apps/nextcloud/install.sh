# prepare data folder
install -m 700 -o dockie -g dockie -d /srv/nextcloud-data

# setting .env variables
echo "NEXTCLOUD_TRUSTED_DOMAINS=$NEXTCLOUD_DOMAIN" >> $HOMEDIR/nextcloud/.env

echo "setting up Caddyfile for nextcloud..."
echo "nextcloud domain: $NEXTCLOUD_DOMAIN"
cat <<EOF >> $HOMEDIR/caddy/Caddyfile
${NEXTCLOUD_DOMAIN} {
    reverse_proxy nextcloud:80
    tls ${EMAIL}
}
EOF

# preparing secrets
mkdir -p $HOMEDIR/nextcloud/secrets/
openssl rand -hex 16 > $HOMEDIR/nextcloud/secrets/nextcloud_admin_user.txt

openssl rand -hex 32 > $HOMEDIR/nextcloud/secrets/mysql_password.txt
openssl rand -hex 32 > $HOMEDIR/nextcloud/secrets/nextcloud_admin_password.txt
openssl rand -hex 32 > $HOMEDIR/nextcloud/secrets/mysql_root_password.txt
