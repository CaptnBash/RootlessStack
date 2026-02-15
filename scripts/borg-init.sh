# check if ssh config file exists
if [ ! -f ~/.ssh/config ]; then
    echo "SSH 'config' file not found!"
    exit 1
fi

set -euo pipefail # fail on error code, unset variables 
umask 0077
source variables.sh
APP=$1
PASSPHRASE_FILE=$BORG_PASSPHRASE_FOLDER/$APP.txt

cd ~/$APP
if ! docker compose config --profiles | grep -x backup > /dev/null; then
    echo "$APP does not have a backup container. Skipping borg initialization."
    exit 0
fi

echo -e "\nInitializing borg repository for app: $APP"

# borg repository setup
if [ -f $PASSPHRASE_FILE ]; then 
    echo "Using existing borg passphrase file"
else
    echo "Creating new borg passphrase file"
    openssl rand -hex 64 > $PASSPHRASE_FILE
fi

export BORG_PASSCOMMAND="cat ${PASSPHRASE_FILE}"

if borg list $BORG_REPO/$APP >/dev/null 2>&1; then
    echo "Borg repo already exists!"
    echo "Skipping initialization..."
else
    borg init --encryption=repokey $BORG_REPO/$APP
    echo "Borg repository initialized!" 
fi
borg key export $BORG_REPO/$APP --paper > $BORG_KEYS_FOLDER/$APP.txt

unset BORG_PASSCOMMAND
