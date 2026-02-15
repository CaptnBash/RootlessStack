# Add Docker's official GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update -qqq
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# disable docker daemon
systemctl disable --now docker.service docker.socket
rm /var/run/docker.sock 2>/dev/null || true

echo "Creating dockie user..."
useradd -m -u 1001 -s /bin/bash dockie

echo "Setting up rootless docker for dockie user..."
loginctl enable-linger dockie
machinectl shell -q dockie@ /usr/bin/dockerd-rootless-setuptool.sh install
echo "Configuring environment for dockie user..."
cp variables.sh $HOMEDIR/

### GAMEZ ###
echo "Creating gamez user..."
useradd -m -u 1002 -s /bin/bash gamez

echo "Setting up rootless docker for gamez user..."
loginctl enable-linger gamez
machinectl shell gamez@ /usr/bin/dockerd-rootless-setuptool.sh install
mkdir -p /home/gamez/minecraft/samples
cp -r apps/minecraft/* /home/gamez/minecraft/samples/  
chown gamez:gamez -R /home/gamez/minecraft/


# install apps
for APP in $APPS; do
  # copy necessary files
  mkdir -p $HOMEDIR/$APP/
  cp apps/$APP/docker-compose.yml $HOMEDIR/$APP/

  # copying variables to environment
  echo "BORG_REPO=$BORG_REPO/$APP" > $HOMEDIR/$APP/.env
  echo "BACKUP_SERVER_SSH_PORT=$BACKUP_SERVER_SSH_PORT" >> $HOMEDIR/$APP/.env
  echo "PASSPHRASE_FILE=$BORG_PASSPHRASE_FOLDER/$APP.txt" >> $HOMEDIR/$APP/.env

  # run app specific install script
  source apps/${APP}/install.sh
done

echo "Setting ownership of home directory to dockie user..."
chown -R dockie:dockie $HOMEDIR

for APP in $APPS; do
  echo "Starting $APP container..."
  machinectl shell -q dockie@ /bin/bash -c "
    until docker compose -f ~/$APP/docker-compose.yml up -d; do
      echo 'Retrying to start $APP...'
      sleep 5
    done"
  sleep 3
  echo "$APP installation done!"
done
