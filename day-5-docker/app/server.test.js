const test = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');

let serverProcess;

// Hook: Chạy server.js ngầm trước khi bắt đầu test
test.before(() => {
    return new Promise((resolve) => {
        // Dùng spawn để chạy lệnh "node server.js"
        serverProcess = spawn('node', ['server.js']);
        
        // Đợi 500ms để chắc chắn server đã khởi động và listen xong
        setTimeout(resolve, 500);
    });
});

// Hook: Bắt buộc tắt tiến trình server sau khi test xong để CI đi tiếp
test.after(() => {
    if (serverProcess) {
        serverProcess.kill();
    }
});

// Test 1: Kiểm tra xem server đã mở chưa (gọi vào port 3000 có trả về status 200 không)
test('Test 1: Server đã mở và phản hồi thành công', async () => {
    const response = await fetch('http://localhost:3000');
    assert.strictEqual(response.status, 200);
});

// Test 2: Kiểm tra xem server có trả về đúng định dạng JSON cơ bản không
test('Test 2: Server trả về đúng nội dung', async () => {
    const response = await fetch('http://localhost:3000');
    const data = await response.json();
    
    // Kiểm tra trong object trả về có chứa thuộc tính 'msg'
    assert.ok(data.msg !== undefined, 'Dữ liệu trả về phải có trường msg');
});
