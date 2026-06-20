1. Liệt kê thứ tự các packet (SYN, SYN-ACK, ACK, HTTP GET, ...)

[SYN]: Client gửi gói tin yêu cầu đồng bộ hóa đến Server (Bắt đầu TCP Handshake).

[SYN, ACK]: Server phản hồi lại, chấp nhận kết nối.

[ACK]: Client xác nhận lại một lần nữa. (Đến đây hoàn thành bắt tay 3 bước TCP).

HTTP GET / HTTP/1.1: Gói tin chứa Request thực sự của Client gửi lên để đòi nội dung trang web.

[ACK]: Server xác nhận đã nhận được yêu cầu GET.

HTTP/1.1 200 OK (hoặc các gói tin TCP chứa dữ liệu): Server trả về nội dung HTML của trang web.

Các gói tin [FIN, ACK] hoặc [RST]: Dùng để đóng/ngắt kết nối sau khi đã truyền xong dữ liệu.

2.
Đã bắt được request vì ở bước 1 ta đã dùng tham số -s 0 (bắt không giới hạn kích thước gói) kết hợp với giao thức HTTP plain text, nên toàn bộ nội dung Header và Body của Request/Response đều được ghi lại trọn vẹn trong file .pcap

Vì sao HTTPS không bắt được payload? Vì giao thức HTTPS kết hợp HTTP với TLS để mã hóa thông tin truyền đi và nhận lại. Toàn bộ phần nội dung HTTP đều bị mã hóa đối xứng thành các chuỗi ký tự ngẫu nhiên trước khi truyền đi

tcpdump hay Wireshark chỉ là bên thứ ba đứng trên đường truyền, không có khóa bí mật này nên chỉ nhìn thấy dữ liệu đã bị mã hóa vô nghĩa chứ không thể giải mã để đọc được Payload gốc.

PART E:
ss -tln: Chỉ liệt kê các cổng giao thức TCP (-t) đang nằm ở trạng thái Lắng nghe connection mới (-l), hiển thị mọi thứ dưới dạng số (-n).

ss -uln: Chỉ liệt kê các cổng giao thức UDP (-u) đang mở sẵn sàng nhận dữ liệu (-l), hiển thị dạng số (-n).

ss -anp: Hiển thị tất cả (-an) các socket trên hệ thống bao gồm cả TCP/UDP, bất kể trạng thái nào (đang lắng nghe, đã kết nối, hoặc đang đóng), đồng thời chỉ rõ tên chương trình/PID nào (-p) đang sở hữu socket đó.

Trạng thái các socket:
LISTEN: Nó có nghĩa là một ứng dụng đã đăng ký thành công một cổng với hệ điều hành và đang nằm im để chờ đợi yêu cầu kết nối gửi tới.

ESTABLISHED: Kết nối giữa Client và Server đã thông suốt hoàn toàn. Cả hai bên đã hoàn thành xong quá trình bắt tay 3 bước

TIME_WAIT: Trạng thái này chỉ xuất hiện ở bên nào chủ động phát lệnh đóng kết nối trước (thường là Client hoặc Web Server sau khi trả xong dữ liệu). Sau khi gửi gói tin xác nhận đóng cuối cùng (ACK) cho bên kia, socket không biến mất ngay mà hệ điều hành bắt nó phải giữ lại ở trạng thái TIME_WAIT trong một khoảng thời gian phòng trường hợp gói tin cuối cùng mất.

CLOSE_WAIT: Trạng thái này xuất hiện ở bên bị động nhận được yêu cầu đóng kết nối từ đối tác. Nhân hệ điều hành thì sẵn sàng đóng, nhưng đang phải xếp hàng chờ ứng dụng (Application Code) ra lệnh đóng hẳn.