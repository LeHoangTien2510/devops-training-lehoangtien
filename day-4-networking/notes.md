1.
OSI (7 lớp): Mô hình lý thuyết, phân chia tường minh trách nhiệm thành 7 tầng riêng biệt (Vật lý, Liên kết dữ liệu, Mạng, Giao vận, Phiên, Trình diễn, Ứng dụng).
TCP/IP (4 lớp): Mô hình thực tế triển khai của Internet. Nó gộp các lớp của OSI lại thành 4 tầng:ứng dụng, giao vận, mạng, truy cập mạng
2.
Client                                      Server
     |                                           |
     | ------------ SYN (Seq=x) ---------------> |  (1. Client muốn kết nối)
     |                                           |
     | <------- SYN-ACK (Seq=y, Ack=x+1) ------- |  (2. Server đồng ý & phản hồi)
     |                                           |
     | ------------ ACK (Ack=y+1) -------------> |  (3. Kết nối được thiết lập)
     v                                           v
3.
Chọn UDP khi ứng dụng ưu tiên tốc độ truyền tải và độ trễ thấp hơn là độ tin cậy tuyệt đối (chấp nhận mất một vài gói tin nhỏ mà không cần truyền lại). Ví dụ như khi: streaming, gaming,...
4.
số ip tương ứng = 2 ^ (32-X) 
X: số bit của subnet mask
/24: 2^(32-24) = 256 IP (Có 254 IP khả dụng cho host).
/16: 2^(32-16) = 65,536 IP (Có 65,534 IP khả dụng cho host).
/22: 2^(32-22) = 1024 IP (Có 1,022 IP khả dụng cho host).
5.
Dải Private IP được sinh ra nhằm mục đích:

Tiết kiệm không gian địa chỉ IPv4: Cho phép hàng triệu mạng nội bộ (mạng LAN gia đình, công ty) tái sử dụng cùng một dải IP mà không lo xung đột trên Internet toàn cầu.

Bảo mật: Các IP này không được định tuyến trên môi trường Internet công cộng, ngăn chặn các truy cập trái phép từ bên ngoài trực tiếp vào thiết bị nội bộ.
6. 
NAT (Network Address Translation) là kỹ thuật thay đổi thông tin địa chỉ IP trong header của gói tin khi nó đi qua một thiết bị định tuyến (Router/Firewall), giúp chuyển dịch giữa IP Private và IP Public.
SNAT (Source NAT): Cho phép các máy trong mạng nội bộ truy cập ra Internet công cộng bằng một IP Public duy nhất. Thay đổi Source IP (IP nguồn) từ Private thành Public khi đi ra ngoài.
DNAT (Destination NAT): Cho phép các máy bên ngoài Internet chủ động kết nối tới một dịch vụ nằm ẩn sau mạng nội bộ. Thay đổi Destination IP (IP đích) từ Public thành Private khi đi vào trong.
7.
Forward Proxy (Proxy xuôi):

Bảo vệ Client (Người dùng).

Vị trí: Đứng trước các Client, đại diện cho Client để gửi yêu cầu lên Internet.

Mục đích: Vượt tường lửa, ẩn danh tính/IP của Client, kiểm soát và lọc nội dung truy cập mạng của nhân viên trong công ty.

Reverse Proxy (Proxy ngược):

Bảo vệ Server (Hệ thống backend).

Vị trí: Đứng trước các Server, đón nhận toàn bộ request từ Internet rồi phân phối vào bên trong.

Mục đích: Cân bằng tải (Load Balancing), giảm tải SSL (SSL Termination), ẩn địa chỉ IP thật của hệ thống backend để chống tấn công (DDoS), caching dữ liệu tĩnh để tăng tốc độ phản hồi.

