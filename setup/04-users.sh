echo "Creating sshuser..."
useradd -m -u 1003 -s /bin/bash sshuser

SSHUSER_PASSWORD=$(openssl rand -base64 32)
ROOT_PASSWORD=$(openssl rand -base64 32)

echo "Storing user credentials..."
echo "sshuser:${SSHUSER_PASSWORD}" > sshuser_credentials.txt # will be deleted by cleanup script
echo "root:${ROOT_PASSWORD}" > root_credentials.txt # will be deleted by cleanup script

echo "Setting passwords for users..."
echo "sshuser:${SSHUSER_PASSWORD}" | chpasswd
echo "root:${ROOT_PASSWORD}" | chpasswd


echo "Creating backupuser..."
useradd -m -s /bin/bash backupuser
passwd -l backupuser

install -m 700 -o backupuser -g backupuser -d /home/backupuser/.ssh
echo "command=\"sudo /usr/local/sbin/monthly-backup\" " > /home/backupuser/.ssh/authorized_keys
chown backupuser:backupuser /home/backupuser/.ssh/authorized_keys

# allow backupuser to run the backup script with sudo
echo "backupuser ALL=(ALL) NOPASSWD: /usr/local/sbin/monthly-backup" > /etc/sudoers.d/monthly-backup
