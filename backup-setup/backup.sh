#!/bin/bash
APP=$1

if [ "$USER" != "dockie" ]; then
    echo "This script must be run as the dockie user. Exiting."
    exit 1
elif [ -z "$APP" ]; then
    echo "Usage: $0 <app-name>"
    exit 1
elif [ ! -d "/home/dockie/$APP" ]; then
    echo "Error: Application directory /home/dockie/$APP does not exist."
    exit 1
fi

cd ~/$APP
if ! docker compose config --profiles | grep -x backup > /dev/null; then
    echo "$APP does not have a backup container. Skipping backup."
    exit 0
fi

# db container should keep running for db dump
docker compose stop $(docker compose config --services | grep -v "^db$")

export BORG_ACTION=BACKUP
export ARCHIVE_NAME=weekly-$(date +%U)
export BACKUP_SERVER_IP=$(grep backupserver /etc/hosts | cut -d ' ' -f1)

if [ -z "$BACKUP_SERVER_IP" ]; then
    echo "Error: Could not find backupserver in /etc/hosts"
    exit 1
fi

echo "Building backup_client..."
docker compose build -q backup
docker compose run --rm backup

docker compose up -d
