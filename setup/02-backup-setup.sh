# https://borgbackup.readthedocs.io/en/stable/usage/serve.html#ssh-configuration

SSH_FOLDER=$HOMEDIR/.ssh
SSH_KEYFILE=${SSH_FOLDER}/borg
BACKUP_FOLDER="$HOMEDIR/backup"


apt install -y borgbackup

# hosts file config
echo -e "\n## CUSTOM\n$BACKUP_SERVER_IP backupserver" >> /etc/hosts

# create necessary folders and copy files
mkdir -p $SSH_FOLDER $BACKUP_FOLDER $BORG_PASSPHRASE_FOLDER $BORG_KEYS_FOLDER
cp -r backup-setup/* $BACKUP_FOLDER

# ssh configuration
CONFIGURATION="Host backupserver
    User borg
    Port $BACKUP_SERVER_SSH_PORT
    IdentityFile ~/.ssh/borg
    ServerAliveInterval 10
    ServerAliveCountMax 30"

printf "$CONFIGURATION\n" >>  $SSH_FOLDER/config

# setting up ssh keys and known hosts
ssh-keygen -t ed25519 -f $SSH_KEYFILE -C "dockie-backup-key" -P ""
if ! ssh-keyscan -p "$BACKUP_SERVER_SSH_PORT" backupserver >> "$SSH_FOLDER/known_hosts"; then
    echo "ERROR: Could not retrieve SSH host key for backupserver."
    echo "Please make sure the backup server is set up correctly and is reachable."
    exit 1
fi
clear
cat $SSH_KEYFILE.pub

echo ""
echo "Store this public key on the backup server for authorization!"
read -p "Press [Enter] to continue..."

# set ownerships
chown -R dockie:dockie $BORG_CONFIG_FOLDER $BACKUP_FOLDER $SSH_FOLDER

cp scripts/borg-init.sh /tmp/
chmod 755 /tmp/borg-init.sh
for APP in $APPS; do
  if [ -f borg-passphrases/$APP.txt ]; then
    install -m 600 -o dockie -g dockie borg-passphrases/$APP.txt $BORG_PASSPHRASE_FOLDER/$APP.txt
  fi
  machinectl shell -q dockie@ /bin/bash /tmp/borg-init.sh $APP
done
