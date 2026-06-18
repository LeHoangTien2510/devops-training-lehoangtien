#!/bin/bash

# 1. Chạy ngầm sleep 300
sleep 300 &
SLEEP_PID=$!

# 2. Hiển thị PPID và PID
echo "PPID: $$ | PID: $SLEEP_PID"

# 3. Gửi SIGTERM và kiểm tra exit code
kill -15 $SLEEP_PID
wait $SLEEP_PID 2>/dev/null
echo "Exit code: $?"