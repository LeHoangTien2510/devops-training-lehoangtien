# Task Submission Template

> Mỗi task = 1 thư mục con + 1 PR/MR riêng. Copy template này vào `README.md` của task.

## Task: `Day 8 - Terraform Basics`

- **Intern**: `Lê Hoàng Tiến`
- **Phase / Week / Day**: `Phase 1 / Week 2 / Day 3`
- **Branch**: `phase-1/week-2/day-3-terraform`
- **Submitted at**: `` (timezone +07)
- **Time spent**: `4h`

## 1. Mục tiêu
Biết cách dùng terraform khởi tạo hạ tầng trên AWS
## 2. Cách chạy
# Chuẩn bị trước khi chạy
Tạo tài khoản aws, tạo user IAM mới, cấp quyền AdministratorAccess, vào phần Credentials lấy access key

```bash
# Dùng lệnh để xác định tài khoản để tạo hạ tầng
aws configure --profile <tên người dùng>
```

# Bài 1

```bash
cd 1-local

# khởi tạo và cấu hình terraform
terraform init

#kiểm tra thay đổi
terraform plan

#triển khai hạ tầng
terraform apply
```
# Bài 2

```bash
cd 2-aws

# khởi tạo và cấu hình terraform
terraform init

#kiểm tra thay đổi
terraform plan

#triển khai hạ tầng
terraform apply
```
## 3. Kết quả
- Screenshot / log output (kèm trong `./screenshots/`).

## 4. Khó khăn & cách giải quyết
-1 vài lúc quên phân quyền cho tài khoản IAM aws nên phải cấu hình lại
## 5. Reference

## 6. Self-check
- [v] Code chạy được trên máy sạch.
- [v] README có hướng dẫn run lại.
- [v] Không hard-code secret.
- [v] Commit message theo Conventional Commits.
- [v] Đã review lại code 1 lượt.