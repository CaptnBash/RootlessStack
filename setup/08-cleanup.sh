#!/bin/bash
# removing default user
DEFAULT_USER=$(id -nu 1000 2>/dev/null || true)
if [ -z "$DEFAULT_USER" ]; then
  echo "No default user to remove."
else
  echo "Removing user: $DEFAULT_USER"

  userdel -r -f "$DEFAULT_USER"
  delgroup "$DEFAULT_USER" 2>/dev/null || echo "Group $DEFAULT_USER already removed."
fi

clear

# print out all secrets for record keeping
echo "================================================================"
echo "User Credentials:"
cat sshuser_credentials.txt
cat root_credentials.txt
if [ -d "$HOMEDIR/nextcloud/secrets" ]; then
echo -e "\n\nNextcloud Secrets:"
for FILE in "$HOMEDIR/nextcloud/secrets"/*; do
  echo "$FILE:"
  cat "$FILE"
done
fi
if [[ $SKIP_BACKUP -eq 0 ]]; then
  echo -e "\nBORG Passphrases and Keys:"
  for FILE in $BORG_PASSPHRASE_FOLDER/*; do
    echo "$FILE:"
    cat "$FILE"
  done
  for FILE in $BORG_KEYS_FOLDER/*; do
    echo "$FILE:"
    cat "$FILE"
  done
  
  echo ""
fi
echo "================================================================"
echo ""
echo "Setup complete! Store these secrets above in a safe place."
echo "Initialize all apps installed before continuing."
echo "Type 'confirm' to acknowledge that you have stored the secrets safely and that all apps are initialized."
read -r CONFIRMATION
while [ "$CONFIRMATION" != "confirm" ]; do
    echo "You must type 'confirm' to proceed."
    read -r CONFIRMATION
done

# deleting setup files
rm -rf "$PWD"

# cleanup secrets
# mysql_password is still used for backups
echo "Removing temporary secrets from the system..." 
if [ -d "$HOMEDIR/nextcloud/secrets" ]; then
  echo "" > $HOMEDIR/nextcloud/secrets/nextcloud_admin_user.txt
  echo "" > $HOMEDIR/nextcloud/secrets/nextcloud_admin_password.txt
  echo "" > $HOMEDIR/nextcloud/secrets/mysql_root_password.txt
fi


read -p "Press [Enter] to power off the system..."

# power off
poweroff 
