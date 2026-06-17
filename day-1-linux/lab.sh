#!/bin/bash

echo "5 process tốn RAM nhất"
ps -eo pid,cmd,%mem --sort=-%mem | head -n 6

echo -e "\nĐếm số file .log trong /var/log (max 2 cấp)"
find /var/log -maxdepth 2 -type f -name "*.log" | wc -l

echo -e "\n10 IP xuất hiện nhiều nhất trong auth.log"
    grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /var/log/auth.log | sort | uniq -c | sort -nr | head -n 10

echo -e "\nĐang ghi thông tin vào file system-info.txt"
echo "host=$(hostname)" > system-info.txt
echo "kernel=$(uname -r)" >> system-info.txt
echo "uptime=$(uptime -p)" >> system-info.txt
echo "Đã ghi xong! Kiểm tra file bằng lệnh: cat system-info.txt"