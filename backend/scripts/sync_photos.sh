#!/bin/bash
# Sync employee photos from GCP c3ais server

REMOTE_PATH="hrisapi@34.177.105.111:/var/www/clients/client3/web5/web/protected/attachments/employeePhoto/"
LOCAL_PATH="/var/www/hris-asuka/backend/storage/app/photo-cache/"

echo "[$(date)] Starting photo sync from GCP..."
rsync -avz --progress "$REMOTE_PATH" "$LOCAL_PATH"
echo "[$(date)] Photo sync completed."
