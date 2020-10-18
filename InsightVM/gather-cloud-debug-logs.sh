#!/bin/bash
##############################################################################
# Tim H 2020
# Description: creates a compressed file containing the logs neccessary
#   to troubleshoot dynamic connections to cloud providers like AWS and Azure
#   It also sets the ownership and permissions so it is easier to SCP off to
#   another system.
##############################################################################

ZIP_PATH="$HOME/cloud_debug_logs-$(date +%F).tar.gz"
sudo tar -czf "$ZIP_PATH" /opt/rapid7/nexpose/nsc/logs/eso.log /opt/rapid7/nexpose/nsc/logs/nsc.log /opt/rapid7/nexpose/nsc/logs/nse.log
sudo chmod +r "$ZIP_PATH"
sudo chown "$USER" "$ZIP_PATH"
ls -lah "$ZIP_PATH"
echo "ZIP file is located at: $ZIP_PATH"
