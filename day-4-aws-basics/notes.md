# 1. 
IAM User (Người dùng): Là một thực thể đại diện cho một người hoặc một ứng dụng cụ thể cần tương tác với AWS. Có thông tin đăng nhập cố định.

IAM Group (Nhóm): Là một tập hợp các IAM User. Group không phải là một thực thể nhận dạng, nó chỉ dùng để gom nhóm các user lại để dễ dàng quản lý và cấp quyền cùng một lúc.

IAM Role (Vai trò): Là một thực thể có các quyền hạn nhất định nhưng không sở hữu thông tin đăng nhập cố định (không có password, không có access key vĩnh viễn). Role sinh ra để cho các đối tượng đáng tin cậy (như EC2, Lambda, hoặc một User từ tài khoản khác) "giả lập" nhằm lấy credential tạm thời có thời hạn ngắn.

IAM Policy (Chính sách): Là một tài liệu (thường ở dạng JSON) định nghĩa quyền hạn (được làm gì và không được làm gì). Bản thân Policy không làm được gì cho đến khi nó được gắn (Attach) vào User, Group, hoặc Role.

Dùng role cho các tác vụ nhỏ, để các dịch vụ aws nói chuyện với nhau. Dùng user khi cần lâu dài, có người quản lý tài khoản đó.

# 2.
Identity-based Policy (Chính sách dựa trên danh tính): Được gắn trực tiếp vào User, Group, hoặc Role. Nó xác định thực thể đó có thể làm gì với các tài nguyên nào.

Resource-based Policy (Chính sách dựa trên tài nguyên): Được gắn trực tiếp vào chính tài nguyên đó (như S3 Bucket, SQS Queue, KMS Key).
Nó xác định ai (Principal nào) có quyền làm gì với tài nguyên này.

Trust Policy (Chính sách tin cậy / Trust Relationship):Là một loại Resource-based policy đặc biệt, nhưng chỉ gắn duy nhất trên IAM Role. Nó định nghĩa ai (Dịch vụ nào như EC2, hay User nào) được phép mượn cái Role này.

# 3.
Việc tạo Access Key (AKIA...) từ một IAM User rồi cấu hình (hardcode) vào EC2 hoặc các công cụ CI/CD (GitHub Actions, Jenkins) gặp rủi ro bảo mật lớn. Sử dụng IAM Role tốt hơn vượt trội vì:

Không sợ lộ Credential: Access Key của IAM User có hiệu lực vĩnh viễn cho đến khi bị xóa thủ công. Nếu ta vô tình push code chứa Key lên GitHub public, hacker sẽ quét ra trong vài giây. Trong khi đó, IAM Role sử dụng Temporary Credentials tự động xoay vòng sau mỗi vài giờ (thường là 1-12 tiếng). Cho dù có lộ credential tạm thời đó, nó cũng tự động hết hạn ngay sau đó.

Không tốn công quản lý: Với EC2, ta chỉ cần gán IAM Role (Instance Profile) vào máy ảo. AWS sẽ tự động lo việc cấp và gia hạn key thông qua dịch vụ Metadata (IMDSv2). Bạn không cần viết script đổi key định kỳ.

Tuân thủ nguyên tắc Least Privilege tối ưu cho CI/CD: Các công cụ CI/CD hiện đại hỗ trợ OIDC (OpenID Connect). GitHub Actions có thể mượn (Assume) một IAM Role của AWS chỉ trong thời gian chạy pipeline chạy, sau khi deploy xong quyền tự động thu hồi mà không cần lưu bất kỳ secret key nào trên GitHub.

# 4.
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject"],
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": { "IpAddress": { "aws:SourceIp": "203.0.113.0/24" } }
  }]
}
```
Version: Định nghĩa phiên bản ngôn ngữ của policy. Giá trị "2012-10-17" là phiên bản hiện tại và tiêu chuẩn của AWS (ko phải ngày tạo policy).

Statement: Khối chứa các quy tắc bảo mật chính (có thể có nhiều statement bên trong dấu []).

Effect: Kết quả của rule này. Ở đây là "Allow" (Cho phép).

Action: Hành động cụ thể được áp dụng. Ở đây là "s3:GetObject", nghĩa là quyền đọc/tải file từ dịch vụ Amazon S3.

Resource: Tài nguyên cụ thể mà hành động trên được phép tác động. Giá trị "arn:aws:s3:::my-bucket/*" chỉ định rõ ràng: Áp dụng cho tất cả các file (đối tượng) nằm bên trong bucket có tên là my-bucket.

Condition: Điều kiện bắt buộc để rule này có hiệu lực. Ở đây sử dụng toán tử "IpAddress" để check biến hệ thống "aws:SourceIp".

Ý nghĩa: Chỉ cho phép thực hiện hành động tải file nếu yêu cầu đó đến từ dải IP nguồn là "203.0.113.0/24". Bất kỳ IP nào nằm ngoài dải này đều bị từ chối.
