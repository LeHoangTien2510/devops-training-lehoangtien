# === STAGE 1: Builder ===
FROM node:24 AS builder
WORKDIR /usr/src/app
# Copy source code vào stage builder 
COPY app/ ./app/

# === STAGE 2: Runtime ===
FROM node:24-alpine AS runtime

# Thiết lập các nhãn tiêu chuẩn OCI (org.opencontainers.image.*)
LABEL org.opencontainers.image.title="Demo Node.js Web App" \
      org.opencontainers.image.description="Thực hành Dockerize web app - Phase 1" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.authors="DevSecOps Student"

WORKDIR /app

# Copy sản phẩm đã tối ưu từ stage builder sang stage runtime ẩn
COPY --from=builder /usr/src/app/app/ ./app/

# Đảm bảo phân quyền thư mục cho user node trước khi chuyển đổi quyền
RUN chown -R node:node /app

# Chuyển sang chạy bằng non-root user có sẵn trên Alpine là 'node' để bảo mật
USER node

# Cấu hình cổng chạy mặc định
EXPOSE 3000

# Thiết lập HEALTHCHECK (Sử dụng wget vì alpine mặc định có sẵn wget, giúp tối ưu size không cần cài curl)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Lệnh khởi chạy ứng dụng
CMD ["node", "app/server.js"]
