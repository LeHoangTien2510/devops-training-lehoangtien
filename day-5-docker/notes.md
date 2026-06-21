1. Các lớp của 1 image
Base Image Layer (Lớp nền đáy):Đây là lớp nằm ở dưới cùng của Image, thường là một hệ điều hành rút gọn như Ubuntu, Alpine, Debian, hoặc một môi trường chạy sẵn như node, python, openjdk. Lớp này chứa các file hệ thống cơ bản cần thiết để các chương trình có thể chạy được.

Intermediate Layers (Các lớp trung gian): mỗi lớp trung gian đại diện cho một thay đổi cụ thể do người dùng định nghĩa thông qua các chỉ thị trong Dockerfile (như RUN, COPY, ADD).

Manifest & Metadata (Lớp thông tin cấu hình): Lớp này lưu trữ các thông tin thiết lập (Metadata) như: các biến môi trường (ENV), port cần mở (EXPOSE), thư mục làm việc (WORKDIR), hay lệnh mặc định khi khởi động (CMD/ENTRYPOINT).

Vì sao layer được cache?
Tăng tốc độ Build: Khi bạn build lại một Image, Docker sẽ kiểm tra xem chỉ thị trong Dockerfile và các file liên quan có gì thay đổi không. Nếu không đổi, nó sẽ tái sử dụng các layer đã build từ trước thay vì phải chạy lại lệnh đó.

Tiết kiệm dung lượng lưu trữ: Nhiều Image hoặc Container khác nhau có thể dùng chung các lớp Base Layer (ví dụ cùng dùng chung layer của ubuntu:22.04), giúp giảm dung lượng ổ đĩa một cách đáng kể.

2.
COPY:

Chức năng: Chỉ có một nhiệm vụ duy nhất và an toàn là copy các file hoặc thư mục từ máy host (máy build) vào bên trong Image.

ADD: 

Chức năng nâng cao: Ngoài copy file từ host, ADD có thêm 2 tính năng:

Cho phép tải file từ một đường dẫn URL từ xa trực tiếp vào Image.

Tự động giải nén các file nén (như .tar, .tar.gz, .gzip) từ máy host vào thư mục đích trong Image.
3.
ENTRYPOINT(cái gì chạy, định dạng cố định): Thiết lập lệnh thực thi chính của container. Khi biến một ứng dụng thành container, ENTRYPOINT chính là cái khung cố định cho biết container này sinh ra để làm gì. Rất khó để ghi đè.

CMD(tham số thêm vào, có thể ghi đè): Định nghĩa các tham số mặc định cho ENTRYPOINT. Nếu Dockerfile không có ENTRYPOINT, thì CMD đóng vai trò là lệnh chạy mặc định.

Khi nào dùng cái nào? 
Trường hợp 1: Chỉ dùng CMD

Khi container là một môi trường chung chung, đa năng. Bạn muốn cung cấp một lệnh chạy mặc định để người dùng bật lên là dùng được ngay, nhưng người dùng có thể dễ dàng đổi sang lệnh khác hoàn toàn khi cần.

Trường hợp 2: Chỉ dùng ENTRYPOINT

Khi container đóng vai trò là một công cụ chuyên biệt hoặc một service cố định. Ta không muốn người dùng thay đổi lệnh thực thi cốt lõi này mà chỉ muốn họ truyền tham số.

Trường hợp 3: Kết hợp cả ENTRYPOINT và CMD

Khi container chạy một ứng dụng cố định (như web server), nhưng bạn muốn linh hoạt thay đổi các tùy chọn/file cấu hình khi khởi động.

4.
.dockerignore giúp loại bỏ các file/thư mục không cần thiết khỏi Build Context (ngữ cảnh build) trước khi gửi dữ liệu lên Docker Daemon.

Tăng tốc độ build: Giảm lượng dữ liệu cần truyền từ máy của bạn sang Docker Daemon (ví dụ loại bỏ các thư mục nặng như node_modules, .git, venv).

Tránh làm hỏng Cache: Nếu các file log, file tạm liên tục thay đổi trên máy host, lệnh COPY . . sẽ liên tục bị mất cache. Thêm chúng vào .dockerignore giúp giữ cache cho các layer ổn định hơn.

Bảo mật thông tin: Ngăn chặn việc vô tình copy các file chứa thông tin nhạy cảm vào trong Image (ví dụ: file cấu hình môi trường .env, private keys, mật khẩu).

5.
Lệnh EXPOSE trong Dockerfile đóng vai trò như một documentation giữa người viết Dockerfile và người vận hành container. Nó thông báo rằng ứng dụng bên trong container có ý định lắng nghe (listen) trên các port cụ thể đó.

EXPOSE không hề tự động mở, publish hay mapping bất kỳ port nào ra ngoài máy host cả. Nó hoàn toàn vô hại nếu đứng một mình.

6.
Mặc định, nếu không chỉ định user, các tiến trình bên trong Docker container sẽ được chạy với quyền root. Điều này vi phạm nghiêm trọng nguyên tắc bảo mật tối thiểu vì:

Rủi ro Container Breakout (Vượt ngục): Nếu ứng dụng có lỗ hổng bảo mật (ví dụ: Remote Code Execution) và hacker chiếm được quyền điều khiển, chúng sẽ có ngay quyền root bên trong container. Từ đó, nếu cấu hình hệ thống hoặc nhân Linux Kernel có lỗ hổng, hacker có thể leo thang đặc quyền để chiếm quyền root của chính máy host vật lý bên ngoài.

Mối đe dọa với Volume Shared: Nếu ta gắn (mount) một thư mục từ máy host vào container, tiến trình chạy quyền root trong container có thể sửa đổi, xóa hoặc tạo các file trên máy host với quyền sở hữu của root, gây lỗi phân quyền hoặc phá hoại hệ thống file của host.