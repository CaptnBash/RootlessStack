set -eu # exit on error and exit on unset variables

echo "Checking Borg repository..."
borg list $BORG_REPO > /dev/null

DUMP_FILE="/backup/db-dump.sql" 

if [ $BORG_ACTION == "BACKUP" ]; then
    echo "Creating backup $ARCHIVE_NAME..."

    if [ -n "${DB_HOST-}" ]; then
        DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
        echo "Dumping database..."
        mariadb-dump --single-transaction \
            --host="$DB_HOST" \
            --user="$DB_USER" \
            --password="$DB_PASSWORD" \
            "$DB_NAME" > "$DUMP_FILE"
    else
        echo "DB_HOST not set, skipping database dump."
    fi

    echo -e "\nDeleting old backup..."
    borg delete $BORG_REPO::$ARCHIVE_NAME --force 2>/dev/null || echo "No backup to delete."

    echo -e "\nCreating backup..."
    borg create --stats $BORG_REPO::$ARCHIVE_NAME /backup

    echo -e "\n\nListing all backups:"
    borg list $BORG_REPO

elif [ $BORG_ACTION == "RESTORE" ]; then
    echo "Restoring backup $ARCHIVE_NAME..."

    echo "Checking if archive exists..."
    borg info $BORG_REPO::$ARCHIVE_NAME >/dev/null

    borg extract $BORG_REPO::$ARCHIVE_NAME

    if [ -f "$DUMP_FILE" ]; then
        DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
        echo "Restoring database..."
        mariadb --host="$DB_HOST" \
            --user="$DB_USER" \
            --password="$DB_PASSWORD" \
            "$DB_NAME" < "$DUMP_FILE"
    else
        echo "No database dump found in the backup. Skipping database restore."
    fi


else
    echo "Invalid BORG_ACTION: $BORG_ACTION"
    echo "Must be 'BACKUP' or 'RESTORE'"
    exit 1
fi
