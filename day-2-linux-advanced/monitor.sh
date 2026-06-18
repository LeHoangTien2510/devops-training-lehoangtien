#!/bin/bash

# Đường dẫn file log cảnh báo 
LOG_FILE="$HOME/monitor.log"

count=0

# hàm xử lý khi nhận tín hiệu SIGINT
graceful_exit() {
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Received SIGINT. Cleaning up and exiting gracefully..."
    exit 0
}

# Đăng ký trap: Khi nhận tín hiệu SIGINT (Ctrl+C), chạy hàm graceful_exit
trap 'graceful_exit' SIGINT

echo "====================================================================="
echo "DevOps Monitoring Script Started..."
echo "Logging warnings to: $LOG_FILE"
echo "====================================================================="

# vòng lặp giám sát mỗi 10 giây

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # 1. Lấy % CPU tổng đang sử dụng
    # Cách tính: 100% trừ đi % của idle (thời gian CPU rảnh lấy từ lệnh top)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # 2. Lấy % MEM (RAM) tổng đang sử dụng
    # Dùng lệnh free để lấy RAM đã dùng chia cho tổng RAM thực tế
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100}')

    # In thông tin tổng quan ra màn hình stdout (để Systemd gom vào log hệ thống)
    echo "---------------------------------------------------------------------"
    echo "[$TIMESTAMP] CPU: ${CPU_USAGE}% | MEM: ${MEM_USAGE}%"
    echo "Top 3 CPU Consuming Processes:"
    
    # 3. Lấy Top 3 tiến trình tốn CPU nhất (Bỏ dòng tiêu đề, lấy 3 dòng đầu)
    ps -eo pid,ppid,%cpu,%mem,cmd --sort=-%cpu | head -n 4 | tail -n 3

    # logic kiểm tra 3 sample liên tiếp hơn 80% cpu
    # Sử dụng awk để so sánh số thập phân (Ví dụ 80.5 > 80)
    IS_EXCEEDED=$(awk -v cpu="$CPU_USAGE" 'BEGIN {print (cpu > 80) ? "YES" : "NO"}')

    if [ "$IS_EXCEEDED" == "YES" ]; then
        count=$((count + 1))
        echo "[DEBUG] CPU exceeded 80% ($count sample(s) consecutive)"
        
        # Nếu chạm ngưỡng 3 lần liên tiếp 
        if [ $count -eq 3 ]; then
            echo "[$TIMESTAMP] WARNING: CPU usage exceeded 80% for 3 consecutive samples (${CPU_USAGE}%)" >> "$LOG_FILE"
            echo "[ALERT] CPU High load! Warning logged to $LOG_FILE"

            count=0
        fi
    else
        # Nếu CPU hạ xuống dưới 80%, lập tức reset biến đếm về 0 để đảm bảo tính "liên tiếp"
        if [ $count -gt 0 ]; then
            echo "[DEBUG] CPU dropped below 80%. Resetting consecutive counter."
        fi
        count=0
    fi

    # Nghỉ 10 giây trước khi quét lượt tiếp theo
    sleep 10
done