## S01:
để xóa lịch sử ta sử dụng công cụ bfg
```bash
# 1. Chạy BFG để quét và xóa file secret.env khỏi toàn bộ lịch sử các commit
bfg --delete-files secret.env
# 2. Thu dọn tài nguyên thừa và cập nhật lại reflog của Git local
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

Các rủi ro còn lại:
1. Hacker có thể đã quét được ngay khi .env bị push lên. Để khắc phục phải truy cập nền tảng cấp phát token đổi token mới
2. Vẫn còn bản sao local của người khác đã pull code về. Bảo họ xóa file đó đi tránh sai lầm.

## S02
Cách 1: Sử dụng git revert
```bash
# 1. Xem lịch sử để tìm hash của commit merge nhầm
git log --oneline

# 2. Sử dụng revert với cờ -m (thường là 1 để quay lại trạng thái của nhánh main trước khi merge)
git revert -m 1 <Mã_Hash_Commit_Merge>

# 3. Push commit revert này lên remote bình thường
git push origin main
```

Cách 2: Sử dụng git reset hard
```bash
# 1. Tìm mã hash của commit cuối cùng hợp lệ trên main (trước commit merge)
git log --oneline

# 2. Đưa nhánh main local về đúng commit hợp lệ đó, xóa sạch code merge nhầm
git reset --hard <Mã_Hash_Commit_Hợp_Lệ>

# 3. Vì lịch sử local lúc này đang cũ hơn remote, force push để đè lịch sử mới lên
git push origin main --force
```

Ưu điểm:
Git revert: An toàn vì vẫn giữ lịch sử commit cũ. Chỉ cần git push thông thường\
Git reset hard: Giúp cây thư mục Git (Git Tree) luôn sạch sẽ, không bị rác bởi các commit sửa lỗi .Xóa triệt để code lỗi

Nhược điểm:
Git revert: Lịch sử Git trông sẽ hơi rối.
Git reset hard: Rất nguy hiểm nếu người khác đã lỡ pull cái commit merge nhầm đó về máy.

## S03
Để xử lý 7 commit gần nhất dùng lệnh
```bash
git rebase -i HEAD~7
```
sửa hành động đầu của mỗi commit trong giao diện hiện lên thành

```bash
pick
s
s
s
s
s
s
```
Sau đó viết lại commit message mới

## S04
Vì HEAD đang đứng ở commit mới nhất vừa viết, chỉ cần tạo một nhánh mới ngay tại đây. Nhánh mới này sẽ tự động lấy toàn bộ lịch sử bao gồm cả 2 commit vừa code.
```bash
# Tạo nhánh mới tên là 'rescue' và chuyển ngay sang nhánh đó
git checkout -b rescue
```

## S05
Bước 1: Xác định và chỉnh sửa file xung đột
```bash
<<<<<<< HEAD
# Code đang có sẵn trên nhánh main
...
=======
# Code mới viết trên nhánh feature
...

>>>>>>>

```
Chọn và giữ lại đoạn code mong muốn sau khi thảo luận với đồng nghiệp.

Bước 2: Đánh dấu file đã sửa xong
Sau khi lưu file app/utils.py đã sửa sạch sẽ.
```bash
git add app/utils.py
```

Bước 3: Tiếp tục tiến trình Rebase
Báo cho git biết đã xử lý xong conflict để Git áp dụng tiếp các commit còn lại trong danh sách
```bash
git rebase --continue
```

1. git rebase --continue: Git sẽ đóng gói các thay đổi vừa sửa vào commit hiện tại và chuyển sang lấy commit tiếp theo của nhánh feature để đè lên nhánh main.
2. git rebase --abort: Git lập tức dừng toàn bộ tiến trình rebase, xóa sạch các vết trạng thái đang làm dở và đưa nhánh của bạn quay trở về trạng thái y hệt như lúc trước khi gõ lệnh git rebase
3. git rebase --skip (Bỏ qua commit này): Dùng khi muốn bỏ hoàn toàn những thay đổi của commit hiện tại trên nhánh feature và chấp nhận lấy toàn bộ code của nhánh main.