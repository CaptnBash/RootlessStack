# redirect rules for rootless caddy
cp /etc/ufw/before.rules /etc/ufw/before.rules.bak
cp setup/ufw.rules /etc/ufw/before.rules
cat /etc/ufw/before.rules.bak >> /etc/ufw/before.rules

# creating networks
machinectl shell -q dockie@ /usr/bin/docker network create nextcloud_caddy
machinectl shell -q dockie@ /usr/bin/docker network create nginx_caddy 
