#!/bin/bash

# ========== CAU HINH ==========
BOT_TOKEN="8744644825:AAHHTHXmgf9Tt03hFHQAGgsG9WtOTFf-em4"
CHAT_ID="8601696069"
BACKUP_DIR="/home/quangdm/monitoring_system/backup/local"
LOG_FILE="/home/quangdm/monitoring_system/backup/logs/backup.log"
GDRIVE_FOLDER="gdrive:ServerBackup"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_$DATE.tar.gz"
SOURCE_DIRS="/home/quangdm/monitoring_system/monitoring"
# ================================

# Ham gui Telegram
gui_telegram() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$1" > /dev/null
}

# Ham ghi log
ghi_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Bat dau backup
ghi_log "===== BAT DAU BACKUP ====="
gui_telegram "Bat dau backup luc $(date '+%H:%M %d/%m/%Y')"

# Tao file backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" $SOURCE_DIRS 2>>"$LOG_FILE"

if [ $? -eq 0 ]; then
  KICH_THUOC=$(du -sh "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
  ghi_log "Tao backup thanh cong: $BACKUP_NAME ($KICH_THUOC)"

  # Upload len Google Drive
  rclone copy "$BACKUP_DIR/$BACKUP_NAME" "$GDRIVE_FOLDER" 2>>"$LOG_FILE"

  if [ $? -eq 0 ]; then
    ghi_log "Upload Google Drive thanh cong"
    gui_telegram "Backup hoan tat!
Ten file: $BACKUP_NAME
Kich thuoc: $KICH_THUOC
Da upload len Google Drive thanh cong"
  else
    ghi_log "Upload Google Drive that bai"
    gui_telegram "Backup xong nhung upload Drive that bai!
Ten file: $BACKUP_NAME
Kiem tra log tai: $LOG_FILE"
  fi

else
  ghi_log "Tao backup that bai"
  gui_telegram "BACKUP THAT BAI luc $(date '+%H:%M %d/%m/%Y')
Kiem tra log tai: $LOG_FILE"
fi

# Xoa backup cu hon 7 ngay
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
ghi_log "Da xoa backup cu hon 7 ngay"
ghi_log "===== KET THUC BACKUP ====="
