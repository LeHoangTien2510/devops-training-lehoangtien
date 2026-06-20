1.
Thêm +trace là cách xem từng bước đường đi của một yêu cầu DNS, giúp bạn biết chính xác tên miền của mình đang bị tắc nghẽn hoặc cấu hình sai ở cấp độ nào (Cấp cao nhất, cấp đuôi tên miền, hay cấp chính chủ).
Nếu chỉ có dig thì ta ko biết tên miền đã được đi thông qua các con đường nào do ta chỉ hỏi đúng DNS resolver của nhà mạng

Giai đoạn 1 (Root Servers): dig gửi truy vấn đến một trong các Root DNS Servers mặc định (có tên từ a.root-servers.net đến m.root-servers.net). Root server không biết IP của google.com ở đâu, nhưng nó biết ai quản lý đuôi .com và trả về danh sách các TLD Nameservers chịu trách nhiệm cho miền .com (ví dụ: a.gtld-servers.net).

Giai đoạn 2 (TLD Servers): dig chọn một TLD server vừa nhận được và gửi câu hỏi. TLD server của .com cũng không biết IP chính xác của google.com, nhưng nó biết máy chủ DNS nào đang quản lý domain này và trả về các Authoritative Nameservers của Google (ví dụ: ns1.google.com, ns2.google.com).

Giai đoạn 3 (Authoritative Servers): dig gửi truy vấn đến một trong các Authoritative Nameservers của Google. Vì đây là nơi giữ chính thức của domain này, nó sẽ trả về kết quả cuối cùng: Bản ghi A record chứa địa chỉ IPv4 của google.com.

Kết quả cuối cùng: Hiển thị IP nhận được cùng với thông tin về kích thước gói tin, thời gian phản hồi (Query time) và thời điểm thực hiện.

2.
![alt text](screenshots/DNS-lab.png.png)

3.
/etc/hosts: Là nơi kiểm tra đầu tiên khi một ứng dụng cần phân giải domain. Nó chỉ là một file text chứa cặp IP - Domain do quản trị viên tự định nghĩa. Thích hợp cho môi trường lab, test local hoặc cấu hình nhanh không cần DNS Server.
/etc/resolv.conf: Là file cấu hình truyền thống chứa địa chỉ của các DNS Server (Nameservers) mà máy tính sẽ gửi truy vấn tới (ví dụ: nameserver 8.8.8.8) nếu không tìm thấy domain trong file /etc/hosts. Thường sẽ là ip của systemd-resolved
systemd-resolved: Là một service quản lý mạng hiện đại của systemd. Nó chịu trách nhiệm gom tất cả các nguồn DNS (từ cấu hình tĩnh, DHCP từ Router, VPN) lại để quản lý tập trung, cung cấp tính năng DNS Caching (nhớ các IP đã phân giải để lần sau không phải hỏi lại giúp tăng tốc độ mạng).

Khi một ứng dụng (như trình duyệt) muốn tìm IP của một trang web:

Nó nhìn vào /etc/hosts trước. Nếu thấy thì lấy luôn.

Nếu không thấy, nó đọc /etc/resolv.conf, thấy ip của systemd và gửi truy vấn tới đó.

systemd-resolved nhận truy vấn. Nó kiểm tra trong bộ nhớ đệm (Cache) của nó, nếu không có sẵn, nó mới đại diện máy tính gửi gói tin ra DNS Server thật ngoài Internet (như 8.8.8.8) để hỏi, sau đó trả kết quả về cho ứng dụng và lưu vào cache.