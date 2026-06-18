# Task Submission Template

> Mỗi task = 1 thư mục con + 1 PR/MR riêng. Copy template này vào `README.md` của task.

## Task: `Day 2 : Linux advanced`

- **Intern**: `Lê Hoàng Tiến`
- **Phase / Week / Day**: `Phase 1 / Week 1 / Day 2`
- **Branch**: `phase-1/week-1/day-2-Linux-Advanced`
- **Submitted at**: `<2026-06-18 15:20>` (timezone +07)
- **Time spent**: `5`

## 1. Mục tiêu
Làm quen với các câu lệnh linux nâng cao
Biết cách viết file systemd.
## 2. Cách chạy
Part A:
```bash
# Cấp quyền thực thi cho script
chmod +x lab-process.sh

# Chạy script để xem demo kết quả
./lab-process.sh
```

Part B:
```bash
# 1. Tạo thư mục làm việc cho webapp
sudo mkdir -p /opt/webapp
sudo chmod 755 /opt/webapp

# 2. Copy file cấu hình vào thư mục quản lý của Systemd
sudo cp webapp.service /etc/systemd/system/

# 3. Ép Systemd quét lại danh sách dịch vụ cấu hình mới
sudo systemctl daemon-reload

# 4. Kích hoạt dịch vụ chạy cùng hệ thống và bật lên ngay lập tức
sudo systemctl enable --now webapp
```

Các bước kiểm tra
```bash
# Kiểm tra trạng thái hoạt động (Xem dòng Active: active (running))
systemctl status webapp

# Xem log đầu ra thời gian thực của ứng dụng web
journalctl -u webapp -f

# TEST CRASH: Tìm PID thực tế rồi ép chết tiến trình (Giả lập ứng dụng bị lỗi)
sudo kill -9 $(pgrep -f "http.server 8080")

# Chờ đúng 3 giây, kiểm tra lại trạng thái để thấy Systemd tự hồi sinh với PID mới
systemctl status webapp
```

Part C
1. Cấp quyền thực thi cho file script
```bash
chmod +x permissions-lab.sh
```
2. Chạy file với quyền sudo để hệ thống tự động thiết lập cấu hình nâng cao
```bash
sudo ./permissions-lab.sh
```

Part D
```bash
# Bước 1: Đăng ký file dịch vụ vào hệ thống Systemd
sudo cp monitor.service /etc/systemd/system/
sudo systemctl daemon-reload

# Bước 2: Bật dịch vụ chạy ngầm ngay lập tức + Tự khởi động khi bật máy
sudo systemctl enable --now monitor.service

# Bước 3: Kiểm tra trạng thái dịch vụ 
systemctl status monitor.service

# Bước 4: Xem log CPU/RAM quét liên tục mỗi 10 giây dưới nền
sudo journalctl -u monitor.service -f

# Bước 5: Thử dừng dịch vụ để kiểm tra tính năng Graceful Exit (Trap tín hiệu)
sudo systemctl stop monitor.service
sudo journalctl -u monitor.service -n 5
```
## 3. Kết quả
- Screenshot / log output (kèm trong `./screenshots/`).

## 4. Khó khăn & cách giải quyết
Lần đầu đối mặt với bash script với systemd nên mất khá nhiều thời gian để hiểu cú pháp.
## 5. Reference

## 6. Self-check
- [v] Code chạy được trên máy sạch.
- [v] README có hướng dẫn run lại.
- [v] Không hard-code secret.
- [v] Commit message theo Conventional Commits.
- [v] Đã review lại code 1 lượt.