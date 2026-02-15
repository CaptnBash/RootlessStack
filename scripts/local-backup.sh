#!/bin/bash
set -u # fail on unset variables 
source ~/variables.sh

MOUNT_FOLDER="/media/PortableSSD"

export BORG_REPO=$MOUNT_FOLDER/backup


if [ "$USER" != "root" ] #check if user is root
then
  echo -ne "Please execute as root!\nExiting!\n"
  exit 1
fi

## checks on mount point
if mountpoint -q "$MOUNT_FOLDER"; then
    echo "ERROR: Something already mounted at $MOUNT_FOLDER"
    exit 1
elif [ "$(ls -A $MOUNT_FOLDER )" ]; then
    echo "ERROR: $MOUNT_FOLDER is not empty!"
    exit 1
fi


mount -U $BACKUP_DRIVE_UUID $MOUNT_FOLDER

echo "Enter Borg passphrase for USB backup:"
read -s BORG_PASSPHRASE
export BORG_PASSPHRASE

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --compression lz4               \
    --exclude-caches                \
    --exclude 'home/*/.cache/*'     \
    --exclude 'var/tmp/*'           \
    --exclude 'root/.cache/borg'    \
    --exclude 'root/.config/borg'   \
                                    \
    ::monthly-'{now:%Y-%m-%d}'      \
    /etc                            \
    /home                           \
    /srv                            \
    /root                           \
    /var                            \
    /usr/local  

borg prune                          \
    --list                          \
    --keep-monthly  12

borg compact

unset BORG_PASSPHRASE
umount $MOUNT_FOLDER
