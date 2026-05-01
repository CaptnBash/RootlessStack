#!/bin/bash
set -u # fail on unset variables

MOUNT_FOLDER="/media/PortableSSD"

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
    --keep-monthly 12

borg compact

unset BORG_PASSPHRASE
umount $MOUNT_FOLDER
