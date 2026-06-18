#!/usr/bin/env bash

# Bật strict mode để script chạy an toàn
set -euo pipefail

# Khai báo thư mục chứa file backup mặc định
BACKUP_DIR="$HOME/backups"

# --- FUNCTION: Hiển thị hướng dẫn sử dụng ---
show_help() {
    echo "Sử dụng: ./backup.sh [thư_mục_cần_backup]"
    echo ""
    # Biến $0 đại diện cho tên của chính file script này
    echo "Tùy chọn:"
    echo "  -h, --help    Hiển thị hướng dẫn này."
    echo ""
    echo "Ví dụ:"
    echo "  ./backup.sh ~/work"
}

# Nếu không truyền tham số nào ($# == 0), hiển thị trợ giúp và thoát lỗi
if [ $# -eq 0 ]; then
    echo "Lỗi: Thiếu tham số truyền vào."
    show_help
    exit 1
fi

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        # Nếu không phải flag help thì gán tham số đó làm thư mục cần backup
        TARGET_DIR="$1"
        ;;
esac

# --- KIỂM TRA THƯ MỤC CÓ TỒN TẠI KHÔNG ---
if [ ! -d "$TARGET_DIR" ]; then
    echo "Lỗi: Thư mục '$TARGET_DIR' không tồn tại trên hệ thống!"
    exit 1
fi

# Tự động tạo thư mục ~/backups nếu chưa có (-p giúp không báo lỗi nếu đã tồn tại)
mkdir -p "$BACKUP_DIR"

DIR_NAME=$(basename "$TARGET_DIR")
# Tạo chuỗi thời gian định dạng YYYYMMDD-HHMMSS
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
# Đặt tên file nén theo đúng format 
BACKUP_FILE="${BACKUP_DIR}/${DIR_NAME}-${TIMESTAMP}.tar.gz"

# Tính toán số lượng file và tổng dung lượng của thư mục mục tiêu
FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$TARGET_DIR" | cut -f1)

echo "Đang tiến hành backup thư mục: $TARGET_DIR"
# -c (create), -z (gzip), -f (file)
tar -czf "$BACKUP_FILE" "$TARGET_DIR"

# --- IN KẾT QUẢ OUTPUT ---
echo "========================================"
echo "Backup thành công!"
echo "File lưu tại: $BACKUP_FILE"
echo "Số lượng file đã backup: $FILE_COUNT"
echo "Tổng dung lượng dữ liệu: $TOTAL_SIZE"
echo "========================================"