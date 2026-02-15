Security-focused self-hosting infrastructure on minimal Debian with rootless Docker, automated encrypted backups, and hardened networking. 

Designed for running web services like Nextcloud with minimal attack surface and full disaster recovery capabilities.

Features two backup strategies: automated remote backups to a server/NAS and manual backups to USB drives for offline redundancy.

This project was mainly developed with my personal goals in mind but I'm happy if you use, modify, or improve it.

# Quick start
Clone this repo and execute the `install.sh` script as `root`.

## Configuration
Before running the setup, review and customize `variables.sh` with your environment settings:
- `NEXTCLOUD_DOMAIN`    - Domain for Nextcloud (e.g., nextcloud.example.com)
- `NGINX_DOMAIN`        - Domain for Nginx (e.g., www.example.com)
- `EMAIL`               - Email for SSL certificates (or "internal" for self-signed)
- `BACKUP_SERVER_IP`    - IP address of backup server
- `BORG_REPO`           - Path to Borg repository on backup server
- `HC_BACKUP_URL`       - healthchecks.io URL for docker backup monitoring

Also check out `root-variables.sh`:
- `HC_UPGRADE_SYSTEM`   - healthchecks.io URL for weekly system upgrade
- `HC_DAILY_URL`        - healthchecks.io URL for daily system healthcheck
- `BACKUP_DRIVE_UUID`   - UUID for backup drive (see [Local Backup](#local-backup-on-separate-drive))

To use the daily and weekly [systemd services](services) you need to set up a project on [healthchecks.io](https://healthchecks.io/) and create 3 checks with the periods matching the [systemd timers](#timers).


## Using an existing Borg repository 

If you want to use an existing Borg repository on a backup server (one that's already been initialized), set the repository passphrase in [borg-passphrases](/borg-passphrases) as \{app-name}.txt (e.g. `nextcloud.txt` for nextcloud).

**WARNING:** If the Borg repository already exists on the backup server and you don't provide the correct passphrase, you will not be able to create or restore backups.

# Setup
## Storage
### Main SSD
The main SSD is the default system drive that hosts most of the directories. 
Debian should mount the main SSD with the layout `direct` to `/`.

## Users/Groups
### dockie
The `dockie` user runs all web based docker applications. This user is locked from interactive shell login for security, but can still execute Docker commands for container management. 

### gamez
The `gamez` user has rootless Docker access for running Minecraft servers. Sample configurations are provided in `apps/minecraft`.

### sshuser
`sshuser` is the only user allowed to be used over `SSH` with a password.

### backupuser
`backupuser` can be used to create backups to a USB drive. Can only be accessed with public key authentication. 

## Network
### Ports
The following ports will be used open on `0.0.0.0`:
```
22: SSH
80:  HTTP (Redirected to 8080)
443: HTTPS (Redirected to 8443)
8080 -> 80: HTTP (Reverse Proxy via Caddy)
8443 -> 443: HTTPS (Reverse Proxy via Caddy)
```

### Firewall
UFW firewall is configured to deny all incoming traffic by default, with explicit allow rules for SSH, HTTP, and HTTPS ports. fail2ban is installed for brute-force protection on SSH.

## Apps
The following apps exist and can be configured with their compose files:

```
nextcloud:  apps/nextcloud/docker-compose.yml
caddy:      apps/caddy/docker-compose.yml
nginx:      apps/nginx/docker-compose.yml
```
There are also some example on how to configure all kinds of minecraft server for the `gamez` user in `apps/minecraft`.

## Secrets
All secrets used during set up are generated using `openssl rand -hex` or `openssl rand -base64`.
This ensures maximum security for all secrets including the username for the admin user in nextcloud.

All docker relevant secrets are stored in each of the applications folder.
Fore example `nextcloud` secrets are in `/home/dockie/nextcloud/secrets` folder. 

This folder is also backed up with borg to ensure no issues appear in a restore if a password was changed or lost. 

## Timers

### daily-healthcheck.timer
- **Schedule:** Daily at 2 AM
- **Script:** `scripts/daily-healthcheck.sh`
- **Purpose:** Checks disk and RAM usage. Fails if either exceeds 80% threshold.

### weekly-upgrade.timer
- **Schedule:** Every Monday at 5 AM
- **Script:** `scripts/weekly-upgrade.sh`
- **Purpose:** System package upgrades, cleanup, and reboot

### docker-backup.timer
- **Schedule:** Every Monday at 6 AM
- **Script:** `scripts/full-docker-backup.sh`
- **Purpose:** Backs up docker volumes using Borg

### Managing Timers
List all timers:
```bash
systemctl list-timers
```

# Automated Backups
## Setup
If you want to set up the remote backup server see the section explaining it here:

[Backup Server](backup-server/README.md)
## Restore
Restoring an application from a Borg backup backup involves extracting configs and secrets as well as rebuilding containers.

### List available backups
```bash
machinectl shell dockie@    # switch to dockie user
APP=nextcloud               # select app you want to restore
source ~/variables.sh
export BORG_PASSCOMMAND="cat ${BORG_PASSPHRASE_FOLDER}/$APP.txt"
borg list $BORG_REPO/$APP
```

This will show all available archives for the application with timestamps.

### Restore an application
Run the restore script as the `dockie` user:
```bash
bash backup/restore.sh <app-name> <archive-name>
```

Example:
```bash
bash backup/restore.sh nextcloud weekly-06
```

The script will:
- Stop and remove existing containers and volumes
- Extract the application files from the archive
- Start the database container (if present) and wait for it to be ready
- Build and run the backup restoration container
- Build and start the app containers
- Rescan files (for Nextcloud)

## Development
For development you can use borg like this:
```
APP=nextcloud
source ~/variables.sh
export BORG_PASSCOMMAND="cat ${BORG_PASSPHRASE_FOLDER}/$APP.txt"
borg list $BORG_REPO/$APP
```

## Logs
`Journalctl` is used for logging. Logs can be read with:
```
journalctl -u docker-backup.service 
```
Note: Should be run as the dockie user.

Append `-a` or `-f` for all logs / following the logs.


# Local Backup on separate drive

## Preparing the drive

### 1. Identify your USB device with `lsblk`. 
### 2. Set the UUID.
Find the UUID with `blkid`. 

Write the UUID into `root-variables.sh` (after setup `/root/variables.sh`).
### 3. Format drive with `parted`:
```
parted /dev/sdX
```
View current partition table:
```
print
```
Create a new partition table (erases everything!):
```
mklabel gpt
```
Create a partition:
```
mkpart primary ext4 0% 100%
```
Exit parted
```
quit
```

### 4. Format the partition
```
mkfs.ext4 /dev/sdX1
```

## Mounting the drive
First create a mount point:
```
mkdir /media/PortableSSD
```
Mount the drive:
```
mount /dev/sdX1 /media/PortableSSD
```


## Creating borg repo
https://borgbackup.readthedocs.io/en/stable/quickstart.html#a-step-by-step-example

Create the repo folder:
```
mkdir /media/PortableSSD/backup
```

Set up the borg repo:
```
export BORG_PASSPHRASE=$(openssl rand -hex 64)

borg init --encryption=repokey /media/PortableSSD/backup
borg key export --paper /media/PortableSSD/backup
echo -e "\nBORG_PASSPHRASE=$BORG_PASSPHRASE"
unset BORG_PASSPHRASE
```
Store the passphrase and the repo key in a safe place.

## Creating backups
To create backups to the USB drive there are two methods.

### backupuser
The setup scripts create a user called `backupuser` that is allowed to run the backup script.

To use it copy your public key to the `/home/backupuser/.ssh/authorized_keys` file.

Then you can start a backup simply with:
```
ssh -t backupuser@192.168.xxx.xxx

# Enter Borg passphrase for USB backup:
```
Note that you will get prompted for the borg passphrase.

### root
Of course you can also log in to the root user and run the backup script from there:
```
monthly-backup
# Enter Borg passphrase for USB backup:
```
You will also need the borg passphrase to create a backup.

## Restoring backups

To restore a backup do the following:
### 1. Make sure the drive is mounted to `/media/PortableSSD`
### 2. Identify what backup you want to restore: 
```
export BORG_PASSPHRASE=<your passphrase>
borg list /media/PortableSSD/backup
```

### 3. Use a temporary folder for recovery:
```
mkdir -p /tmp/restore
cd /tmp/restore
```

### 4. Restore the archive
```
# restore everything
borg extract /media/PortableSSD/backup::monthly-2026-February-15

# restore single folder
borg extract /media/PortableSSD/backup::monthly-2026-February-15 home/gamez
```
