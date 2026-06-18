# cài đặt các gói cần thiết
sudo apt update && sudo apt install -y acl

# Tạo group devops, user và thư mục
sudo groupadd devops

sudo useradd -m khach

sudo mkdir -p /tmp/shared-lab

# Đổi group sở hữu của thư mục này thành 'devops'
sudo chown :devops /tmp/shared-lab

# Cấp quyền Đọc/Ghi/Vào thư mục (rwx) cho cả Owner và Group sở hữu
sudo chmod 770 /tmp/shared-lab

# Thêm bit SGID cho thư mục
sudo chmod g+s /tmp/shared-lab

# Tạo file bên trong thư mục shared-lab và cấu hình quyền
sudo touch /tmp/shared-lab/secret.txt

sudo chmod 400 /tmp/shared-lab/secret.txt

# Cấu hình ACL cho user 'khach' với quyền đọc (r) và thực thi (x - để chui được vào thư mục)
sudo setfacl -m u:khach:rx /tmp/shared-lab

getfacl /tmp/shared-lab