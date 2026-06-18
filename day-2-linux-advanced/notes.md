1.
SIGINT: Gửi tín hiệu ngừng đến tiến trình. Nó yêu cầu tiến trình dừng lại ngay lập tức nhưng có mở hàm dọn dẹp
SIGTERM: Tín hiệu tắt lịch sự mặc định của hệ thống, yêu cầu tiến trình hoàn thành nốt các tác vụ dang dở, ghi log rồi tự đóng một cách an toàn
SIGKILL: Tín hiệu hủy diệt do Kernel thực hiện, ép tiến trình sập nguồn ngay lập tức mà không cho phép dọn dẹp, dễ gây lỗi hỏng dữ liệu
SIGHUP: Tín hiệu yêu cầu tiến trình tải lại các file cấu hình mới mà không cần phải tắt hoàn toàn ứng dụng, giúp hệ thống hoạt động liên tục không gián đoạn.
2.
nohup: Chạy lệnh mới bám vào Terminal hiện tại nhưng chặn tín hiệu SIGHUP; khi Terminal tắt, tiến trình mới tách ra thành mồ côi và được PID 1 nhận nuôi.

disown: Áp dụng cho lệnh đang chạy sẵn, xóa nó khỏi danh sách quản lý của Terminal hiện tại để không bị chết dây chuyền khi Terminal đóng.

setsid: Chạy lệnh mới và chủ động ly khai ngay lập tức, tự tạo một Session độc lập và làm con nuôi của PID 1 (systemd) ngay từ giây đầu tiên.
3.
pkill -f quét và đối chiếu từ khóa với toàn bộ chuỗi dòng lệnh đầy đủ (bao gồm cả trình thông dịch, đường dẫn file và các tham số phía sau), thay vì chỉ tìm theo tên tiến trình gốc ngắn gọn.

Khi nào dùng: 
1. Khi cần giết các script (.sh, .py, .js) mà tên tiến trình thực tế của chúng hiển thị trong hệ thống chỉ là bash, python, node.
2. Khi cần lọc và giết chính xác một tiến trình dựa theo tham số cấu hình hoặc cổng mạng cụ thể (ví dụ: giết app chạy riêng ở --port 8080).
3. Khi tên file thực thi quá dài (vượt quá giới hạn 15 ký tự) và bị hệ thống cắt cụt.

4.
R(Running / Runnable - Đang chạy hoặc Sẵn sàng chạy): đang chạy hoặc có thể chạy
S(Interruptible Sleep - Ngủ có thể ngắt): Tiến trình đang ở trạng thái ngủ để chờ một sự kiện hoặc tài nguyên hệ thống
D (Uninterruptible Sleep - Ngủ không thể ngắt): Tiến trình đang ngủ cực kỳ sâu để chờ một tác vụ I/O phần cứng trực tiếp (thường là đợi ghi dữ liệu vào ổ đĩa nén). Trạng thái này không thể bị đánh thức bởi bất kỳ Signal nào
Z (Zombie - Tiến trình ma / Thây ma): Tiến trình đã kết thúc hoàn toàn công việc của nó (đã chết), nhưng tiến trình cha của nó chưa gọi hàm wait() để giải phóng và thu dọn nốt exit code của nó ra khỏi bảng quản lý tiến trình
T (Stopped - Bị tạm dừng): Tiến trình đang bị đóng băng/đình chỉ tạm thời bởi một tín hiệu điều khiển công việc

5.
Zombie Process (Tiến trình ma) là một tiến trình đã hoàn thành việc thực thi và đã chết hoàn toàn, nhưng vẫn có tên và giữ một vị trí trong bảng quản lý tiến trình (Process Table) của hệ điều hành Linux.
Các cách phát hiện tiến trình ma:
Cách 1: Sử dụng lệnh top hoặc htop
Ngay ở dòng đầu tiên của lệnh top, hệ thống sẽ thống kê tổng số lượng tiến trình đang có, trong đó có một mục dành riêng cho Zombie
Cách 2: Sử dụng lệnh ps và lọc theo cột STAT (Tìm chính xác)
Zombie có ký tự nhận diện trong cột STAT là Z
