#!/usr/bin/env bash
# Deployt Befragung + Live-Auswertung auf den Shiny-Server (ssh-Alias "appserver").
#   https://shiny-appserver.org/hochsensibilitaet/       -> Fragebogen
#   https://shiny-appserver.org/hochsensibilitaet-live/  -> Live-Plots
set -euo pipefail
cd "$(dirname "$0")"

ssh appserver 'mkdir -p /tmp/hsp_deploy/hochsensibilitaet /tmp/hsp_deploy/hochsensibilitaet-live'
scp befragung/app.R hsp.R appserver:/tmp/hsp_deploy/hochsensibilitaet/
scp live/app.R hsp.R appserver:/tmp/hsp_deploy/hochsensibilitaet-live/

ssh appserver 'set -e
  sudo mkdir -p /var/lib/hochsensibilitaet
  sudo chown shiny:shiny /var/lib/hochsensibilitaet
  sudo chmod 750 /var/lib/hochsensibilitaet
  for app in hochsensibilitaet hochsensibilitaet-live; do
    sudo mkdir -p /srv/shiny-server/$app
    sudo cp /tmp/hsp_deploy/$app/* /srv/shiny-server/$app/
    sudo touch /srv/shiny-server/$app/restart.txt
  done
  rm -rf /tmp/hsp_deploy
  ls -l /srv/shiny-server/hochsensibilitaet /srv/shiny-server/hochsensibilitaet-live'
