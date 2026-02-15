#!/bin/bash
set -euo pipefail # fail on error code, unset variables and pipeline fails on error code
umask 0077

# make sure the current working directory is set to the root folder of the repo
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR" || exit 1

SKIP_BACKUP=0


echo "Updating and upgrading system packages..."
apt update -qqq
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -qqq
clear

source variables.sh

source setup/00-system-settings.sh

source setup/01-docker-setup.sh

echo "Checking if backup server is reachable..."
if ping -c 3 $BACKUP_SERVER_IP > /dev/null; then
    source setup/02-backup-setup.sh
else
    SKIP_BACKUP=1
    echo "Backup server is not reachable. Skipping backup setup."
fi

source setup/03-services.sh

source setup/04-users.sh

source setup/05-hardening.sh

source setup/08-cleanup.sh
