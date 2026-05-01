#!/bin/bash
source ~/variables.sh
curl $HC_BACKUP_URL/start >/dev/null 2>&1

for APP in $APPS; do
  if ! bash ~/backup/backup.sh $APP; then
    curl $HC_BACKUP_URL/fail >/dev/null 2>&1
    exit 1
  fi
done

curl $HC_BACKUP_URL >/dev/null 2>&1
