#!/bin/bash
source ~/variables.sh

for APP in $APPS; do
  cd ~/$APP || continue
  docker compose pull
  docker compose up -d 
done

docker image prune -af
