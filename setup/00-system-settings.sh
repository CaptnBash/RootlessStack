# issue
cp setup/issue /etc/issue

cp root-variables.sh /root/variables.sh

echo "umask 0077" >> /etc/profile
echo "umask 0077" >> /etc/skel/.bashrc
echo "umask 0077" >> /etc/bash.bashrc

# MOTD
rm /etc/motd
chmod a-x /etc/update-motd.d/10-uname 2>/dev/null || true

# bahrc
cp setup/bashrc /etc/skel/.bashrc
cp setup/bashrc /root/.bashrc

# installing necessary packages 
apt update -qqq
apt install -y ca-certificates curl dbus-user-session htop openssl sudo systemd-container ufw uidmap vim
