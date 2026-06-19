1. Tạo một commit thử nghiệm bằng lệnh:

```bash
git commit -m "test reflog loss"
```

2. Xóa commit đó bằng lệnh
```bash
git reset --hard HEAD~1
```
3. Kiểm tra mã commit SHA
```bash
git reflog
```
4. Khôi phục commit bị mất sang một nhánh mới tên là recovered
```bash
git checkout -b recovered <Điền_Mã_SHA_Vào>
```