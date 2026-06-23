# 1.
Để retry nhanh mà không cần build lại, chúng ta tận dụng cơ chế Docker Layer Caching. 
Sử dụng GitHub Actions Cache (hoặc Inline Cache): Cấu hình Docker Buildx để đẩy các layer đã build thành công lên cache của GitHub. Khi retry, Docker sẽ nhận diện các layer cũ không thay đổi và lấy trực tiếp từ cache ra, sau đó tiến thẳng đến step Push.

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ghcr.io/${{ github.repository }}/demo-app:${{ github.ref_name }}
    cache-from: type=gha # Lấy cache từ GitHub Actions
    cache-to: type=gha,mode=max # Ghi đè cache tối đa để tái sử dụng
```
GitHub hiện tại đã hỗ trợ tính năng "Re-run failed jobs" thay vì phải chạy lại toàn bộ Workflow.
# 2.
Cách 1:
Sử dụng công cụ SSH trực tiếp vào Runner
Sử dụng các Action bên thứ ba như mxschmitt/action-tmate hoặc csexton/debugger-action để cài một cổng SSH ngược (Reverse SSH) vào chính con Runner đang chạy của GitHub.
Chèn step này vào ngay trước step bị lỗi trong file .yml:
```yaml
- name: Setup tmate session
  uses: mxschmitt/action-tmate@v3
```
Khi chạy đến đây, Job sẽ tạm dừng và in ra một đường dẫn SSH trong log. Ta có thể mở Terminal ở máy local, SSH thẳng vào con Runner đó để gõ lệnh debug trực tiếp.

Cách 2: Bật chế độ Debug Log hệ thống của GitHub
Thêm 2 biến Secret này vào Repository (Settings > Secrets and variables > Actions):

ACTIONS_RUNNER_DEBUG = true

ACTIONS_STEP_DEBUG = true

Lúc này, GitHub sẽ in ra toàn bộ log ẩn chi tiết của hệ thống (system calls, tiến trình chạy ngầm của runner) để tìm ra nguyên nhân.

# 3.
needs: Mặc định các Job trong GitHub chạy song song. Needs giúp thiết lập mối quan hệ phụ thuộc thứ tự giữa các Job (Job nào chạy trước, Job nào chạy sau).

if: Thiết lập điều kiện rẽ nhánh. Quyết định xem một Job/Step có được phép chạy hay không.

concurrency: Kiểm soát số lượng Job chạy song song. Ngăn chặn xung đột khi có nhiều người push code cùng lúc.

# 4.
Không còn nỗi lo lộ Key: 

Static Key: Có giá trị vô thời hạn. Nếu vô tình làm lộ key này (hoặc nội bộ có biến động), hacker có thể dùng nó để vào AWS phá hoại bất kỳ lúc nào.

OIDC: GitHub và AWS sẽ tự nói chuyện với nhau qua cơ chế tin tưởng (Trust Relationship). Mỗi khi pipeline chạy, AWS sẽ cấp một Token tạm thời chỉ có hiệu lực trong vài phút. Chạy xong Token tự hủy, dù có lộ cũng không ai dùng lại được.

Không cần quản lý và gia hạn: Ta không cần phải copy-paste Key thủ công lên GitHub, cũng không cần lo kịch bản "Key hết hạn giữa đêm" gây sập pipeline.

Phân quyền tinh chỉnh tối đa: Với OIDC, ta cấu hình gán một IAM Role cụ thể trên AWS cho đúng Repository đó.