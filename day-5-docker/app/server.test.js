const test = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');

let serverProcess;

// Hàm tiện ích để kill server một cách an toàn
const killServer = () => {
    if (serverProcess && !serverProcess.killed) {
        serverProcess.kill('SIGKILL'); // Dùng SIGKILL để ép buộc tắt ngay lập tức
    }
};

// ĐĂNG KÝ BẢO HIỂM: Nếu tiến trình test bị crash/tắt bất ngờ, tắt luôn server con
process.on('exit', killServer);
process.on('SIGINT', killServer);
process.on('SIGTERM', killServer);
process.on('uncaughtException', (err) => {
    killServer();
    process.exit(1);
});

// Hook: Chạy server.js ngầm trước khi bắt đầu test
test.before(() => {
    return new Promise((resolve, reject) => {
        serverProcess = spawn('node', ['server.js']);

        // Nếu server con bị lỗi ngay khi bật, không bắt CI đợi nữa mà fail luôn
        serverProcess.on('error', (err) => {
            reject(err);
        });
        
        // Đợi 500ms để chắc chắn server đã khởi động và listen xong
        setTimeout(resolve, 500);
    });
});

// Hook: Tắt tiến trình server sau khi các test chạy xong (luồng thành công)
test.after(() => {
    killServer();
});

// Test 1: Kiểm tra xem server đã mở chưa
test('Test 1: Server đã mở và phản hồi thành công', async () => {
    try {
        const response = await fetch('http://localhost:3000');
        assert.strictEqual(response.status, 200);
    } catch (error) {
        killServer(); // Thất bại thì chủ động giải phóng port ngay
        throw error;  // Báo lại lỗi để Node test runner ghi nhận pass/fail
    }
});

// Test 2: Kiểm tra xem server có trả về đúng định dạng JSON cơ bản không
test('Test 2: Server trả về đúng nội dung', async () => {
    try {
        const response = await fetch('http://localhost:3000');
        const data = await response.json();
        assert.ok(data.msg !== undefined, 'Dữ liệu trả về phải có trường msg');
    } catch (error) {
        killServer(); // Thất bại thì chủ động giải phóng port ngay
        throw error;  // Báo lại lỗi để Node test runner ghi nhận pass/fail
    }
});
