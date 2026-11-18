#!/usr/bin/env bash
# Deployt Befragung + Live-Auswertung auf den Shiny-Server (ssh-Alias "appserver").
#   https://shiny-appserver.org/einsamkeit/       -> Fragebogen
#   https://shiny-appserver.org/einsamkeit-live/  -> Live-Plots
set -euo pipefail
cd "$(dirname "$0")"

ssh appserver 'mkdir -p /tmp/kse_deploy/einsamkeit /tmp/kse_deploy/einsamkeit-live'
scp befragung/app.R kse.R appserver:/tmp/kse_deploy/einsamkeit/
scp live/app.R kse.R appserver:/tmp/kse_deploy/einsamkeit-live/

ssh appserver 'set -e
  sudo mkdir -p /var/lib/einsamkeit
  sudo chown shiny:shiny /var/lib/einsamkeit
  sudo chmod 750 /var/lib/einsamkeit
  for app in einsamkeit einsamkeit-live; do
    sudo mkdir -p /srv/shiny-server/$app
    sudo cp /tmp/kse_deploy/$app/* /srv/shiny-server/$app/
    sudo touch /srv/shiny-server/$app/restart.txt
  done
  rm -rf /tmp/kse_deploy
  ls -l /srv/shiny-server/einsamkeit /srv/shiny-server/einsamkeit-live'
