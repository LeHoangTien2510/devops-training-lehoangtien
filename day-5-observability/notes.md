# 1
Log: Là bản ghi lại một sự kiện cụ thể xảy ra tại một thời điểm chính xác. Log mang tính chất chi tiết, thường ở dạng văn bản (Text/JSON) và có dung lượng lớn.

Metric(Số liệu đo lường): Là dữ liệu số học được tích lũy và đo lường theo thời gian. Metric rất nhẹ, có thể lưu trữ lâu dài và dùng để vẽ biểu đồ, thiết lập cảnh báo (Alert).

Trace (Dấu vết yêu cầu): Là hành trình của một single request đi qua toàn bộ các dịch vụ của hệ thống (từ Frontend $\rightarrow$ API Gateway $\rightarrow$ Auth Service $\rightarrow$ DB). Một Trace gồm nhiều Span (mỗi đoạn xử lý nhỏ).

# 2
Pull-based (Prometheus)
Cơ chế: Server giám sát chủ động gửi request định kỳ để kéo dữ liệu metric từ các ứng dụng/target về.

Ưu điểm: Server tự điều tiết tốc độ cào để không bị quá tải, dễ phát hiện target sống/chết và không cần cấu hình mạng phức tạp cho server.

Nhược điểm: Khó giám sát các tác vụ ngắn hạn vì chúng có thể tắt trước khi kịp cào, đồng thời yêu cầu mở cổng mạng để server chọc vào ứng dụng.

Push-based (StatsD, OpenTelemetry Collector)
Cơ chế: Ứng dụng hoặc agent cài kèm giữ thế chủ động, tự gom số liệu rồi đẩy thẳng về server giám sát theo chu kỳ hoặc theo sự kiện.

Ưu điểm: Tuyệt vời cho các tác vụ ngắn hạn (Serverless, Lambda, CronJobs) vì ứng dụng cứ chạy xong là tự đẩy dữ liệu lên, dễ dàng đi qua tường lửa (Outbound traffic).

Nhược điểm: Dễ gây sập server giám sát khi có bùng nổ traffic (DDoS ngược do hàng ngàn máy chủ đồng loạt push về) và khó phân biệt máy chủ bị sập hay hệ thống đang rảnh.

# 3
SLI (Service Level Indicator - Chỉ số): Là thước đo thực tế về chất lượng dịch vụ tại một thời điểm (hệ thống thực tế đang chạy thế nào?).

SLO (Service Level Objective - Mục tiêu): Là mục tiêu nội bộ của đội ngũ kỹ thuật tự đề ra để hướng tới (chúng ta muốn hệ thống chạy tốt ở mức nào?).

SLA (Service Level Agreement - Cam kết): Là cam kết mang tính pháp lý/kinh doanh với khách hàng (nếu hệ thống không đạt mức này, chúng ta sẽ phải đền tiền).

Ví dụ:
SLI (Thước đo thực tế): Công ty dùng công cụ giám sát (như Prometheus) để đo: Tỷ lệ các request thanh toán thành công (HTTP status 200) trên tổng số request đổ về hệ thống.

SLO (Mục tiêu nội bộ): Đội ngũ SRE và Dev họp lại và đưa ra mục tiêu nếu SLI tụt xuống dưới 99.9%, hệ thống cảnh báo (Alert) sẽ bắn về để đội kỹ thuật dậy sửa lỗi ngay, mặc dù khách hàng có thể chưa kịp phàn nàn.

SLA (Cam kết pháp lý): Công ty ký hợp đồng thương mại với các đối tác chấp nhận thanh toán: "Chúng tôi cam kết dịch vụ hoạt động ổn định đạt 99.5% mỗi tháng. Nếu trong tháng đó, tỷ lệ hoạt động tụt dưới 99.5%, chúng tôi sẽ hoàn lại 20% phí dịch vụ của tháng đó."

# 4
Cardinality được định nghĩa bằng tổng số chuỗi thời gian (unique time-series) được tạo ra mỗi khi  kết hợp một Tên Metric với các cặp Label khác nhau, nó sẽ tạo ra 1 tổ hợp duy nhất.

Nổ cardinality là hiện tượng số lượng chuỗi thời gian (unique time-series) tăng vọt theo cấp số nhân do vô tình đưa các dữ liệu có giá trị vô hạn (như User ID, Order ID, UUID) vào làm Label của metric.

Hậu quả là bộ nhớ RAM của Prometheus bị cạn kiệt lập tức dẫn đến sập hệ thống (OOM), đồng thời khiến các biểu đồ trên Grafana bị nghẽn, tải chậm hoặc không thể hiển thị dữ liệu.


