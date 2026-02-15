#!/bin/bash
source ~/variables.sh

APP=$1
BORG_REPO=$BORG_REPO/$APP
PASSPHRASE_FILE=$BORG_PASSPHRASE_FOLDER/$APP.txt
MYSQL_ROOT_PASSWORD=~/$APP/secrets/mysql_root_password.txt

export ARCHIVE_NAME=$2
export BACKUP_SERVER_IP=$(grep backupserver /etc/hosts | cut -d ' ' -f1)
export BORG_PASSCOMMAND="cat ${PASSPHRASE_FILE}"
export BORG_ACTION=RESTORE

if [ "$USER" != "dockie" ]; then
    echo "This script must be run as the dockie user. Exiting."
    exit 1
elif [ -z "$BACKUP_SERVER_IP" ]; then
    echo "Error: Could not find backupserver in /etc/hosts"
    exit 1
elif [ -z "$APP" ]; then
    echo "Usage: $0 <app-name> <archive-name>"
    exit 1
elif [ ! -d "/home/dockie/$APP" ]; then
    echo "Error: Application directory /home/dockie/$APP does not exist."
    exit 1
elif [ -z "$ARCHIVE_NAME" ]; then
    echo "Error: Archive name must be provided as the second argument."
    echo "Usage: $0 $APP <archive-name>"
    echo -e "\nAvailable backups:"
    borg list $BORG_REPO
    exit 1
fi

cd ~/$APP

# remove existing containers and volumes
docker compose down
docker volume rm $(docker compose volumes -q)

# restoring app directory first
# without this changed variables in .env or secrets won't be applied for backup container
borg extract $BORG_REPO::$ARCHIVE_NAME /backup/app --strip-components 2

# restore db if present
if docker compose config --services | grep -x db > /dev/null; then
    # generating new mysql root password
    clear
    echo -e "Restoring database container...\n\n"

    echo "$(openssl rand -hex 32)" > $MYSQL_ROOT_PASSWORD
    echo "$MYSQL_ROOT_PASSWORD:"
    cat $MYSQL_ROOT_PASSWORD

    echo -e "\n\nGenerated new mysql root password. Store this secret in a safe place."
    echo "Type 'confirm' to acknowledge that you have stored the secrets safely and that all apps are initialized."
    read -r CONFIRMATION
    while [ "$CONFIRMATION" != "confirm" ]; do
        echo "You must type 'confirm' to proceed."
        read -r CONFIRMATION
    done

    docker compose up db -d
    sleep 10 # wait for db to be ready
fi 

echo "Building backup_client..."
docker compose build -q backup

# restoring backup 
docker compose run --rm backup

docker compose up -d

if [ "$APP" == "nextcloud" ]; then
    echo "Rescanning Nextcloud files..."
    docker compose exec --user www-data nextcloud php occ files:scan --all
fi
