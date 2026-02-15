#!/bin/bash
set -euo pipefail # fail on error code, unset variables and pipeline fails on error code
source ~/variables.sh
curl $HC_BACKUP_URL/start >/dev/null 2>&1 || true

for APP in $APPS; do
  bash ~/backup/backup.sh $APP
done

curl $HC_BACKUP_URL >/dev/null 2>&1 || true
