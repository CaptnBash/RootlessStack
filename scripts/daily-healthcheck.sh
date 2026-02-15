#!/bin/bash
set -euo pipefail # fail on error code, unset variables and pipeline fails on error code
source ~/variables.sh
THRESHOLD=80

## Healthcheck start
curl $HC_DAILY_URL/start >/dev/null 2>&1 || true

# Clean up unused docker resources
# DO NOT USE --all HERE, IT WILL BREAK DATABASE CONTAINERS
machinectl shell -q dockie@ /usr/bin/docker volume prune -f

# Check disk usage
df -h --output=source,pcent -x tmpfs -x devtmpfs | tail -n +2 | while read -r line; do
    FILESYSTEM=$(echo "$line" | awk '{print $1}')
    USAGE=$(echo "$line" | awk '{print $2}' | cut -d'%' -f1)

    echo "$FILESYSTEM: $USAGE%"

    if [ "$USAGE" -gt "$THRESHOLD" ]; then
        echo "Warning: Disk usage is above ${THRESHOLD}% on $FILESYSTEM!"
        curl $HC_DAILY_URL/fail >/dev/null 2>&1 || true
        exit 1
    fi
done

# Check ram usage
MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
RAM_USAGE=$(( (MEM_TOTAL - MEM_AVAILABLE) * 100 / MEM_TOTAL ))

echo "RAM Usage: ${RAM_USAGE}%"
if [ "$RAM_USAGE" -gt "$THRESHOLD" ]; then
    echo "Warning: RAM usage is above ${THRESHOLD}%!"
    curl $HC_DAILY_URL/fail >/dev/null 2>&1 || true
    exit 1
fi

curl $HC_DAILY_URL >/dev/null 2>&1 || true
