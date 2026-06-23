# 1.
State file (terraform.tfstate) là gì?

Là một file định dạng JSON được Terraform sử dụng làm "nguồn thông tin đáng tin cậy duy nhất" (Single Source of Truth).

Nó lưu trữ bản đồ ánh xạ (mapping) giữa các cấu hình bằng code của bạn (.tf) và các tài nguyên thực tế đã được tạo ra trên Cloud.

Nó giúp Terraform biết được tài nguyên nào đã tồn tại, thuộc tính của chúng là gì để tính toán các thay đổi cho lần chạy tiếp theo.

Vì sao không được commit lên Git?

Lộ bí mật: State file lưu trữ tất cả thông tin ở dạng text thuần, bao gồm cả các dữ liệu nhạy cảm như mật khẩu database, database credentials,... Nếu đưa lên Git, ta sẽ bị lộ thông tin bảo mật ngay lập tức.

Xung đột dữ liệu: Nếu nhiều người cùng code và commit file này lên Git, việc merge code rất dễ gây ra conflict cấu trúc JSON của state. Khi state bị hỏng, Terraform sẽ không thể quản lý hạ tầng một cách chính xác nữa.

Không cập nhật thời gian thực: Git là công cụ quản lý phiên bản code, không phải là hệ thống lưu trữ trạng thái động. State file thay đổi liên tục sau mỗi lệnh apply, Git không thể đồng bộ hóa tức thời cho các thành viên khác trong team trước khi họ chạy lệnh.

# 2.
terraform plan: Xem trước các thay đổi sẽ diễn ra. Chỉ kiểm tra, không tạo/sửa/xóa gì cả.

terraform apply: Thực thi và áp dụng các thay đổi vào hạ tầng thực tế. Cập nhật file state ngay sau khi tài nguyên thay đổi thành công.

terraform refresh: Cập nhật trạng thái của State file cho khớp với thực tế. Không tạo/sửa/xóa tài nguyên. Chỉ đọc dữ liệu từ Cloud về.

# 3.
Khi làm việc nhóm, nếu lưu state file ở máy cục bộ (Local Backend) thì người khác sẽ không có dữ liệu để chạy. Do đó ta cần đưa state lên một nơi tập trung (Remote Backend). Mô hình kết hợp AWS S3 + DynamoDB là tiêu chuẩn công nghiệp vì giải quyết được các vấn đề sau:

Lưu trữ tập trung và an toàn (S3):

Giúp cả team dùng chung một file state duy nhất.

S3 hỗ trợ mã hóa giúp bảo vệ dữ liệu nhạy cảm.

S3 hỗ trợ Versioning (quản lý phiên bản). Nếu lỡ làm hỏng file state hiện tại, ta có thể dễ dàng rollback lại phiên bản state cũ trước đó.

Cơ chế khóa State (DynamoDB Lock):

Nếu 2 người cùng gõ terraform apply vào cùng một thời điểm. Nếu không có gì ngăn chặn, cả hai lệnh cùng ghi đè lên file state sẽ làm nát dữ liệu hạ tầng.

Khi dùng DynamoDB, người nào chạy lệnh trước sẽ kích hoạt một cái Khóa (Lock). Lệnh của người thứ hai sẽ bị từ chối và phải đợi cho đến khi người thứ nhất chạy xong. Điều này ngăn chặn hoàn toàn tình trạng Race Condition (giành giật tài nguyên).

# 4.
Module Local: Nằm ngay trong ổ cứng máy tính. Không hỗ trợ tag version trực tiếp trong code gọi module. Code ở thư mục đó có gì thì chạy nấy. Phù hợp cho các dự án nhỏ, cấu trúc thư mục nội bộ đơn giản, hoặc khi đang trong quá trình phát triển/thử nghiệm module.

Module Registry: Nằm trên Internet. Có hỗ trợ thuộc tính version. Giúp khóa phiên bản để tránh code bị lỗi khi module gốc cập nhật đột ngột. Phù hợp để chia sẻ code giữa nhiều phòng ban, nhiều dự án khác nhau trong công ty, hoặc tận dụng các module chuẩn hóa do cộng đồng AWS/Terraform viết sẵn.

# 5.
count (Vòng lặp dựa trên Số lượng / Index Số nguyên): Nhận vào một số nguyên (ví dụ: count = 3). Terraform sẽ tạo ra các tài nguyên theo dạng mảng/danh sách với các chỉ số [0], [1], [2]. Dùng để tạo các tài nguyên giống hệt nhau 

for_each (Vòng lặp dựa trên Khóa định danh / Key-Value): Nhận vào một Set (tập hợp các chuỗi) hoặc một Map (cặp Key-Value). Các tài nguyên tạo ra được định danh bằng chính cái Key đó thay vì số thứ tự (Ví dụ: aws_instance.web["api_server"]). Dùng khi các tài nguyên có sự khác biệt về thuộc tính. Khi số lượng tài nguyên có thể tăng/giảm hoặc thay đổi vị trí thường xuyên.

# 6.
Drift (Trôi dạt hạ tầng): Là hiện tượng xuất hiện sự sai lệch giữa cấu hình hạ tầng thực tế trên Cloud và những gì được khai báo trong code Terraform (hoặc dữ liệu trong State file).

Cách phát hiện:

Chạy lệnh terraform plan.

Lúc này, Terraform sẽ chạy refresh ngầm để quét hạ tầng thực tế, đối chiếu với State và Code. Nó sẽ hiển thị thông báo chi tiết: "Objects have changed outside of Terraform" và chỉ ra chính xác thuộc tính nào đang bị lệch.

Cách xử lý:

Hướng 1-Muốn giữ lại thay đổi thực tế: phải cập nhật lại Code .tf cho khớp chính xác với thông số mới ngoài cloud đó Sau đó chạy terraform apply để đồng bộ lại State file.

Hướng 2 - Muốn hủy bỏ thay đổi thực tế: chỉ cần giữ nguyên Code và chạy trực tiếp lệnh terraform apply. Terraform sẽ tự động đè cấu hình cũ trong code lên Cloud, xóa bỏ hoàn toàn sự thay đổi thủ công kia.