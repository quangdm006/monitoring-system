#!/bin/bash

# ========== CAU HINH ==========
BOT_TOKEN="8744644825:AAHHTHXmgf9Tt03hFHQAGgsG9WtOTFf-em4"
CHAT_ID="8601696069"
LOG_FILE="/home/quangdm/monitoring_system/user_mgmt/logs/user_mgmt.log"
CSV_FILE="/home/quangdm/monitoring_system/user_mgmt/data/users.csv"
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

# Ham tao nhom neu chua ton tai
tao_nhom() {
  local NHOM=$1
  if ! getent group "$NHOM" > /dev/null 2>&1; then
    groupadd "$NHOM"
    ghi_log "Da tao nhom: $NHOM"
  fi
}

# Ham tao user
tao_user() {
  local USERNAME=$1
  local GROUP=$2
  local EXPIRE=$3

  tao_nhom "$GROUP"

  if id "$USERNAME" > /dev/null 2>&1; then
    ghi_log "User da ton tai: $USERNAME - bo qua"
    return
  fi

  useradd -m -g "$GROUP" -e "$EXPIRE" -s /bin/bash "$USERNAME"

  PASSWORD=$(openssl rand -base64 10)
  echo "$USERNAME:$PASSWORD" | chpasswd
  chage -d 0 "$USERNAME"

  ghi_log "Da tao user: $USERNAME | Nhom: $GROUP | Het han: $EXPIRE"
  gui_telegram "Da tao user moi:
Ten: $USERNAME
Nhom: $GROUP
Het han: $EXPIRE
Mat khau tam: $PASSWORD"
}

# Ham xoa user
xoa_user() {
  local USERNAME=$1

  if ! id "$USERNAME" > /dev/null 2>&1; then
    ghi_log "User khong ton tai: $USERNAME"
    return
  fi

  userdel -r "$USERNAME" 2>>"$LOG_FILE"
  ghi_log "Da xoa user: $USERNAME"
  gui_telegram "Da xoa user: $USERNAME"
}

# Ham phan quyen theo nhom
phan_quyen() {
  local GROUP=$1

  case "$GROUP" in
    admin)
      usermod -aG sudo "$2"
      ghi_log "Da cap quyen sudo cho: $2"
      ;;
    developer)
      mkdir -p /opt/app
      chown root:"$GROUP" /opt/app
      chmod 775 /opt/app
      ghi_log "Da cap quyen developer cho: $2"
      ;;
    readonly)
      ghi_log "Da tao user readonly: $2"
      ;;
  esac
}

# Ham import user tu CSV
import_csv() {
  ghi_log "===== BAT DAU IMPORT USER TU CSV ====="
  gui_telegram "Bat dau import user tu file CSV"

  tail -n +2 "$CSV_FILE" | while IFS=',' read -r USERNAME GROUP EXPIRE; do
    USERNAME=$(echo "$USERNAME" | tr -d ' ')
    GROUP=$(echo "$GROUP" | tr -d ' ')
    EXPIRE=$(echo "$EXPIRE" | tr -d ' ')

    tao_user "$USERNAME" "$GROUP" "$EXPIRE"
    phan_quyen "$GROUP" "$USERNAME"
  done

  ghi_log "===== KET THUC IMPORT USER ====="
  gui_telegram "Hoan tat import user tu CSV"
}

# Menu chinh
echo "=============================="
echo "  QUAN LY USER HE THONG"
echo "=============================="
echo "1. Import user tu file CSV"
echo "2. Tao user thu cong"
echo "3. Xoa user"
echo "4. Xem danh sach user"
echo "5. Xem audit log"
echo "=============================="
read -p "Chon chuc nang (1-5): " CHON

case $CHON in
  1)
    import_csv
    ;;
  2)
    read -p "Ten user: " U
    read -p "Nhom (admin/developer/readonly): " G
    read -p "Ngay het han (YYYY-MM-DD): " E
    tao_user "$U" "$G" "$E"
    phan_quyen "$G" "$U"
    ;;
  3)
    read -p "Ten user muon xoa: " U
    xoa_user "$U"
    ;;
  4)
    echo "====== DANH SACH USER ======"
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
    ;;
  5)
    echo "====== AUDIT LOG ======"
    cat "$LOG_FILE"
    ;;
  *)
    echo "Lua chon khong hop le!"
    ;;
esac
