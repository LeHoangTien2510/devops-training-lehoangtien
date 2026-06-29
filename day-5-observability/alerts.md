Latency Alert: Phát hiện sớm tình trạng phản hồi chậm của Web App trước khi người dùng nhận thấy hệ thống bị "treo".
Error Rate Alert: Phát hiện các lỗi phát sinh từ code, mất kết nối cơ sở dữ liệu, hoặc lỗi bên thứ ba (HTTP 5xx).
Saturation Alert: Đo lường mức độ đầy của tài nguyên (CPU, Memory, Connection Pool) để kịp thời nâng cấp hoặc xử lý memory leak trước khi sập ứng dụng.

Phân Biệt Alert "Noise" vs Alert "Actionable"
Alert "Noise" (Cảnh báo nhiễu): Cảnh báo về các sự cố tự phục hồi, mang tính nhất thời, hoặc không cần con người can thiệp ngay lập tức. Ví dụ: CPU đột ngột tăng lên 90% trong 1 phút do cronjob chạy. 

Alert "Actionable" (Cảnh báo có giá trị): Cảnh báo yêu cầu kỹ sư phải xử lý ngay lập tức để ngăn chặn/giảm thiểu thiệt hại. Thường dựa trên Triệu chứng / Trải nghiệm người dùng (Symptom-based).

Ví dụ: Khách hàng không thể thanh toán (Error 500).
Phải kích hoạt PagerDuty, Opsgenie, hoặc cuộc gọi trực tiếp tới kỹ sư On-call. Luôn đi kèm một Runbook (Sách hướng dẫn xử lý) rõ ràng: lỗi này xử lý ra sao, liên hệ ai.