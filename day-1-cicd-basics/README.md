Link github:https://github.com/LeHoangTien2510/devops-training-lehoangtien/tree/phase-1/week-2/day-1-cicd-basics
Link repo có workflow: https://github.com/LeHoangTien2510/devops-training-lehoangtien/tree/phase-1/week-1/day-5-docker
Link image: docker pull ghcr.io/lehoangtien2510/demo-app:latest
Run number của pipeline pass:#8, id = 27938070827

# Task Submission Template

> Mỗi task = 1 thư mục con + 1 PR/MR riêng. Copy template này vào `README.md` của task.

## Task: `Day 6 — CICD-basics`

- **Intern**: `Lê Hoàng Tiến`
- **Phase / Week / Day**: `Phase 1 / Week 2 / Day 1`
- **Branch**: `phase-1/week-2/CICD-basics`
- **Submitted at**: `<>` (timezone +07)
- **Time spent**: `4h`

## 1. Mục tiêu
Hiểu CICD là gì, luồng hoạt động CICD cơ bản, cách tạo file CICD và cấu hình kiểm tra bảo mật
## 2. Cách chạy

## 3. Kết quả
- Screenshot / log output (kèm trong `./screenshots/`).

## 4. Khó khăn & cách giải quyết
-Tên github là tên có kí tự hoa nên phải viết lại file ci để đổi tên thành lowercase
-Phải cấu hình thêm work directory vào thư mục /app 
-Pipeline khi test fail bị kẹt cứng, phải thêm khối try catch và kill test khi đã fail ko chạy lại
## 5. Reference

## 6. Self-check
- [v] Code chạy được trên máy sạch.
- [v] README có hướng dẫn run lại.
- [v] Không hard-code secret.
- [v] Commit message theo Conventional Commits.
- [v] Đã review lại code 1 lượt.