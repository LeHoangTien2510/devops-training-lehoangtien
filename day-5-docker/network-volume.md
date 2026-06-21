```bash
#1 khởi tạo network và kết nối với network

docker network create demo-net

docker run -d --name app2 --network demo-net demo-app:1.0.0

#thêm cờ -rm để tự động xóa container khi exit

docker run --rm -it --name app1 --network demo-net demo-app:1.0.0 sh


#2. Tạo container postgresql gắn volume ra bên ngoài db pgdata được quản lý bởi docker

docker run -d --name test-db -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=mysecretpassword postgres:16-alpine

docker exec -it test-db psql -U postgres -c "CREATE DATABASE devsecops_db;"

#Thử xóa db

docker rm -f test-db

#tạo lại db mới và gắn vào volume cũ

docker run -d --name test-db-recovered -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=mysecretpassword postgres:16-alpine

#3: mount volume

#tạo thư mục site, thêm nội dung vào index.html và mount vào thư mục /html trong container nginx
mkdir site && echo "<h1>Hello Phase 1</h1>" > site/index.html$ docker run -d --name test-nginx -p 8081:80 -v "$PWD/site:/usr/share/nginx/html" nginx:alpine
curl localhost:8080
```

node:20: Chứa đầy đủ mọi công cụ phát triển, trình biên dịch (gcc, g++), các lệnh Linux phổ biến, package manager. Dễ bị hacker tấn công, chỉ nên dùng ở build stage

node:20-slim: Đã lược bỏ các công cụ build nâng cao và các tài liệu hướng dẫn, chỉ giữ lại môi trường Node.js và các thư viện OS tối thiểu. 

node:20-alpine: Chạy trên nhân Alpine cực kỳ tối giản, sử dụng thư viện hệ thống musl libc (thay vì glibc của Debian) và trình quản lý gói apk. Siêu nhẹ, bảo mật cực tốt

distroless/nodejs20: Chỉ chứa duy nhất môi trường chạy Node.js và các file cấu hình múi giờ/chứng chỉ bắt buộc. Hacker hoàn toàn không thể phá hoại vì ko có terminal. Rất khó debug trực tiếp bằng CLI khi có sự cố.
