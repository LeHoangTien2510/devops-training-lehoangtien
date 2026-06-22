# 1.
CI (Continuous Integration - Tích hợp liên tục): Quá trình tự động hóa việc build và test code ngay sau khi lập trình viên commit/push code mới vào kho lưu trữ chung giúp phát hiện lỗi sớm.

CD (Continuous Delivery - Chuyển giao liên tục): Tiếp nối sau CI. Sau khi build và test thành công, code tự động được đóng gói và chuẩn bị sẵn sàng để deploy lên môi trường Production.

Continuous Deployment (Triển khai liên tục): Mọi thay đổi vượt qua được các bước test của CI/CD sẽ tự động deploy thẳng lên Production mà không cần bất kỳ sự can thiệp thủ công nào của con người.

# 2.
DORA (DevOps Research and Assessment) đưa ra 4 chỉ số cốt lõi để đo lường hiệu suất và độ hiệu quả của một đội ngũ kỹ thuật phần mềm. 4 chỉ số này được chia làm hai nhóm: Tốc độ và Độ ổn định.

Nhóm Tốc độ 

Deployment Frequency (Tần suất triển khai): Đo lường mức độ thường xuyên code được deploy thành công lên Production. Tần suất càng cao chứng tỏ hệ thống càng linh hoạt.

Lead Time for Changes (Thời gian thay đổi): Khoảng thời gian từ khi code bắt đầu được commit cho đến khi nó chạy chính thức trên Production. Chỉ số này thấp chứng tỏ quy trình CI/CD và feedback loop hoạt động rất nhanh.

Nhóm Độ ổn định
Change Failure Rate (Tỷ lệ triển khai thất bại): Tỷ lệ phần trăm các lần deploy lên Production gây ra lỗi nghiêm trọng hoặc sập hệ thống, cần phải rollback hoặc hotfix. Tỷ lệ này càng thấp càng tốt.

Time to Restore Service (Thời gian khôi phục dịch vụ - MTTR): Thời gian cần thiết để hệ thống quay lại trạng thái hoạt động bình thường sau khi xảy ra sự cố trên Production. Chỉ số này thấp thể hiện khả năng giám sát và ứng phó sự cố tốt.

# 3.
Pipeline as Code (PaC) là việc định nghĩa toàn bộ quy trình CI/CD bằng file cấu hình text (ví dụ: .github/workflows/ci.yml, Jenkinsfile) lưu trực tiếp trong Git repo, thay vì click chọn trên giao diện đồ họa (UI) của công cụ.

Các ưu điểm vượt trội:
Quản lý phiên bản: Pipeline được lưu trong Git, giúp dễ dàng theo dõi ai đã sửa đổi gì, so sánh các phiên bản, và rollback về cấu hình cũ khi gặp lỗi.

Tái sử dụng và Nhân bản nhanh: Dễ dàng copy file cấu hình áp dụng cho hàng chục project khác nhau mà không cần tốn thời gian vào UI click lại từ đầu.

Đồng bộ với Code: File cấu hình nằm chung với source code. Khi tạo một branch mới cho tính năng mới, bạn có thể sửa đổi pipeline riêng cho branch đó mà không ảnh hưởng đến branch chính.

Code review và phê duyệt: Các thay đổi của pipeline phải đi qua Pull Request (PR), giúp team có thể review, thảo luận và duyệt trước khi áp dụng.

# 4. Khi nào dùng runs-on: self-hosted vs ubuntu-latest?

Dùng ubuntu-latest (Hosted Runner do GitHub quản lý) khi:
Dự án tiêu chuẩn, phổ thông: Không đòi hỏi cấu hình phần cứng quá đặc biệt hay tài nguyên quá lớn.

Muốn tiện lợi, không tốn công quản lý: Ta không cần quan tâm đến việc bảo trì, cập nhật OS, hay bảo mật cho máy chạy runner. GitHub lo hết.


Dùng runs-on: self-hosted (Runner tự cài đặt trên server riêng) khi:
Cần bảo mật và kết nối nội bộ: Khi pipeline cần truy cập vào database nội bộ, mạng VPN private, hoặc deploy trực tiếp lên hạ tầng local (On-premise) mà không muốn mở port ra Internet công cộng.

Cần tối ưu chi phí cho tần suất chạy lớn: Đối với các repo private chạy CI/CD liên tục, việc tự host server riêng sẽ rẻ hơn nhiều so với việc trả tiền mua thêm block phút chạy của GitHub.

Đòi hỏi cấu hình phần cứng đặc thù: Project lớn cần build siêu nhanh bằng CPU nhiều nhân, RAM khủng, hoặc cần dùng GPU để build/test các tác vụ nặng (như training, đóng gói model AI).

Kiểm soát môi trường: Cần cài sẵn các công cụ, dependencies nặng hoặc cấu hình OS cố định mà Hosted Runner của GitHub không hỗ trợ hoặc mất thời gian cài lại mỗi lần chạy.


