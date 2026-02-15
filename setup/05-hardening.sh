# disable login for dockie and gamez
usermod -p '!' dockie
usermod -p '!' gamez

echo "Applying firewall rules..."
ufw default deny incoming
ufw default allow outgoing

echo "Disabling IPv6 in UFW..."
sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw

ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw allow 8443/tcp

ufw --force enable

cp setup/sshd_settings.conf /etc/ssh/sshd_config.d/99-server-setup.conf
if ! systemctl restart ssh; then
    echo "Warning: SSH restart failed" >&2
fi

echo "Disabling unnecessary services..."
systemctl disable --now cron.service


#################
## libpam-tmpdir creates a temporary directory for each user in /tmp on login
## apt-listchanges shows changelogs before package installation
## fail2ban to protect ssh and other services from brute-force attacks
apt install -y libpam-tmpdir apt-listchanges fail2ban 
