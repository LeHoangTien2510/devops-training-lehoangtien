ls: Liệt kê danh sách các file và thư mục trong thư mục hiện tại.
cd: Thay đổi thư mục làm việc hiện tại để chuyển sang thư mục khác.
pwd: Hiển thị đường dẫn đầy đủ của thư mục hiện tại đang đứng.
mkdir: Tạo một thư mục mới.
rm: Xóa file hoặc thư mục
cp: Sao chép file hoặc thư mục từ vị trí này sang vị trí khác.
mv: Di chuyển hoặc đổi tên file, thư mục.
touch: Tạo nhanh một file trống mới hoặc cập nhật thời gian chỉnh sửa của file.
cat: Đọc và hiển thị toàn bộ nội dung của một file ra màn hình.
less: Xem nội dung file theo từng trang
head: Hiển thị các dòng đầu tiên của một file
tail: Hiển thị các dòng cuối cùng của một file
grep: Tìm kiếm các dòng chứa chuỗi ký tự hoặc định dạng cụ thể trong file hoặc văn bản.
find: Tìm kiếm file hoặc thư mục dựa trên tên, kích thước, thời gian hoặc quyền sở hữu.
xargs: Nhận đầu ra của lệnh trước để làm tham số đầu vào cho lệnh tiếp theo.
awk: Công cụ xử lý văn bản và trích xuất dữ liệu mạnh mẽ theo từng cột (trường).
sed: Bộ biên tập dòng lệnh dùng để tìm kiếm, thay thế hoặc chỉnh sửa văn bản trực tiếp.
sort: Sắp xếp các dòng trong file văn bản theo thứ tự bảng chữ cái hoặc số.
uniq: Loại bỏ các dòng trùng lặp liền kề nhau trong văn bản.
wc: Đếm số dòng, số từ và số ký tự có trong một văn bản.
tee: Đọc dữ liệu từ đầu vào rồi vừa ghi ra file vừa hiển thị ra màn hình terminal.
ps: Hiển thị danh sách các tiến trình (process) đang chạy tại thời điểm hiện tại.
top: Xem danh sách các tiến trình và mức độ tiêu thụ CPU, RAM của hệ thống theo realtime
htop: Giao diện trực quan và đẹp hơn của lệnh top, cho phép tương tác bằng chuột/bàn phím.
kill: Gửi tín hiệu để dừng hoặc ép buộc tắt một tiến trình đang chạy thông qua ID (PID).
nice: Thiết lập mức độ ưu tiên sử dụng CPU cho một tiến trình khi nó bắt đầu chạy.
df: Hiển thị dung lượng đĩa cứng còn trống và đã sử dụng của các phân vùng trên hệ thống.
du: Ước tính và hiển thị dung lượng đĩa cứng mà một file hoặc thư mục cụ thể đang chiếm dụng.
free: Hiển thị tổng dung lượng và trạng thái sử dụng của bộ nhớ RAM và Swap.
uptime: Cho biết hệ thống đã hoạt động liên tục được bao lâu và mức độ tải
uname: Hiển thị thông tin chi tiết về hệ điều hành và phiên bản Kernel Linux đang dùng.
who: Xem danh sách các tài khoản người dùng hiện đang đăng nhập vào hệ thống.
chmod: Thay đổi quyền truy cập (đọc, ghi, thực thi) của file hoặc thư mục.
chown: Thay đổi chủ sở hữu (user) hoặc nhóm sở hữu (group) của file hoặc thư mục.
umask: Thiết lập các quyền mặc định sẽ bị loại bỏ khi tạo file hoặc thư mục mới.
tar: Gom nhiều file/thư mục thành một file lưu trữ duy nhất hoặc giải nén chúng
gzip: Nén file đơn lẻ thành định dạng .gz để giảm dung lượng hoặc giải nén lại.
zip: Nén nhiều file và thư mục thành định dạng .zip phổ biến.
unzip: Giải nén các file có định dạng .zip.
ssh: Kết nối và điều khiển một máy chủ từ xa một cách bảo mật qua giao diện dòng lệnh.
scp: Sao chép file bảo mật giữa máy cục bộ và máy chủ từ xa thông qua giao thức SSH.
rsync: Đồng bộ hóa file và thư mục giữa hai vị trí một cách tối ưu bằng cách chỉ truyền phần thay đổi.
ln: Tạo một liên kết cứng (Hard Link) trỏ thẳng tới cùng một dữ liệu của file trên ổ đĩa.
ln -s: Tạo một liên kết mềm (Symbolic Link / Shortcut) trỏ tới đường dẫn của file hoặc thư mục khác.
env: Hiển thị toàn bộ danh sách các biến môi trường hiện tại hoặc chạy lệnh trong một môi trường tùy chỉnh.
export: Tạo mới hoặc xuất một biến thường thành biến môi trường để các tiến trình con có thể dùng.
source: Chạy trực tiếp các câu lệnh trong một file cấu hình ngay tại shell hiện tại để cập nhật thay đổi.
curl: Chuyển dữ liệu từ/đến server thông qua các giao thức (HTTP, HTTPS, FTP...), thường dùng để test API.
wget: Tải các file từ internet về máy thông qua đường dẫn URL công khai.
which: Hiển thị đường dẫn chính xác của file thực thi (lệnh) hệ thống sẽ gọi khi gõ lệnh đó.
whereis: Tìm kiếm vị trí file thực thi, file mã nguồn và trang hướng dẫn của một lệnh.
type: Kiểm tra xem một lệnh là lệnh tích hợp sẵn của Shell, file thực thi độc lập hay là bí danh (alias).
history: Hiển thị danh sách lịch sử các câu lệnh đã từng gõ trên terminal.
alias: Tạo một tên gọi tắt (bí danh) tự định nghĩa cho một câu lệnh dài hoặc phức tạp.
echo: In một đoạn văn bản hoặc giá trị của một biến ra màn hình terminal.
printf: In văn bản ra màn hình có định dạng nâng cao