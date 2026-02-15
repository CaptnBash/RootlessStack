echo "NGINX_DOMAIN=$NGINX_DOMAIN" > $HOMEDIR/$APP/.env

cat <<EOF >> $HOMEDIR/caddy/Caddyfile
${NGINX_DOMAIN} {
    reverse_proxy nginx:80
    tls ${EMAIL}
}
EOF

cp -r apps/nginx/html $HOMEDIR/nginx/

# https://github.com/nginx/docker-nginx/issues/177
echo "Setting permissions for nginx html files..."
chmod 644 $HOMEDIR/nginx/html/*
chmod 755 $HOMEDIR/nginx/html
