# redirect rules for rootless caddy
cp /etc/ufw/before.rules /etc/ufw/before.rules.bak
cp setup/ufw.rules /etc/ufw/before.rules
cat /etc/ufw/before.rules.bak >> /etc/ufw/before.rules

# all networks are created even if not used
# otherwise docker compose would fail if the networks were missing
machinectl shell -q dockie@ /usr/bin/docker network create nextcloud_caddy
machinectl shell -q dockie@ /usr/bin/docker network create nginx_caddy 

install -o dockie -g dockie -m 660 /dev/null $HOMEDIR/caddy/Caddyfile
