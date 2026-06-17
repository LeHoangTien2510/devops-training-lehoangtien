# Task Submission Template

> Mỗi task = 1 thư mục con + 1 PR/MR riêng. Copy template này vào `README.md` của task.

## Task: `Day 1 — Linux Fundamentals`

- **Intern**: `Lê Hoàng Tiến`
- **Phase / Week / Day**: `Phase 1 / Week 1 / Day 1`
- **Branch**: `phase-1/week-1/day-1-linux`
- **Submitted at**: `<2026-6-17 5:10>` (timezone +07)
- **Time spent**: `4h`

## 1. Mục tiêu
Hiểu cách sử dụng các lệnh linux cơ bản, cách kết hợp các lệnh với nhau. Tạo bash script cơ bản để backup files.

## 2. Cách chạy
1. Chuẩn bị trước khi chạy 

```bash
chmod +x lab.sh backup.sh
```
2. Cách chạy file lab.sh
```bash
./lab.sh
```
Kiểm tra kết quả câu 4 bằng lệnh 
```bash
cat system-info.txt
```

Nếu muốn đếm cả file trong /var/log/private
```bash
sudo ./lab.sh
```
3. Cách chạy file backup.sh
Xem hướng dẫn sử dụng (Help Flag)
```bash
./backup.sh --help
# Hoặc
./backup.sh -h
```
Chạy kiểm tra cơ chế bắt lỗi
```bash
./backup.sh /duong/dan/ao/khong/ton/tai
```
Chạy thực hiện backup thật
Tiến hành nén và lưu trữ một thư mục cụ thể (Ví dụ nén thư mục ~/work):
```bash
./backup.sh ~/work
```

## 3. Kết quả
- Screenshot / log output (kèm trong `./screenshots/`).

## 4. Khó khăn & cách giải quyết
-1 vài câu lệnh linux ít dùng nên em đã mất nhiều thời gian hơn để hiểu nó.
-Các lệnh linux kết hợp ở phần lab tương đối dài và mất nhiều thời gian để hiểu cách xử lý
-Do lần đầu dùng ngôn ngữ bash nên phải mất nhiều thời gian kiểm tra cú pháp
## 5. Reference

## 6. Self-check
- [v] Code chạy được trên máy sạch.
- [v] README có hướng dẫn run lại.
- [v] Không hard-code secret.
- [v] Commit message theo Conventional Commits.
- [v] Đã review lại code 1 lượt.