# executed by dockie
install -m 755 scripts/docker-image-upgrade.sh /usr/local/bin/docker-image-upgrade.sh
install -m 755 scripts/full-docker-backup.sh /usr/local/bin/full-docker-backup.sh

### services ###
install -m 700 scripts/daily-healthcheck.sh /usr/local/sbin/daily-healthcheck.sh
install -m 700 scripts/weekly-upgrade.sh /usr/local/sbin/weekly-upgrade.sh

cp services/* /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now daily-healthcheck.timer weekly-upgrade.timer

if [[ $SKIP_BACKUP -eq 0 ]]; then
  systemctl enable --now docker-backup.timer
fi


# system scripts
install -m 700 scripts/local-backup.sh /usr/local/sbin/monthly-backup
