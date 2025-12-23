const { spawn } = require("child_process");
const http = require("http");

// ==========================================
// 1. 定义伪装网站 (Web Server)
// ==========================================

// 这是一个看起来很正规的“站点维护中”页面
// 它可以欺骗通过浏览器直接访问你域名的人，或者 Lunes 的自动截图审计
const fakeHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Service Maintenance</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #f0f2f5; color: #333; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .container { text-align: center; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 400px; width: 100%; }
        h1 { font-size: 24px; margin-bottom: 10px; color: #e74c3c; }
        p { line-height: 1.6; color: #666; }
        .footer { margin-top: 20px; font-size: 12px; color: #999; }
    </style>
</head>
<body>
    <div class="container">
        <h1>System Update</h1>
        <p>Our backend services are currently undergoing scheduled maintenance to improve performance.</p>
        <p>Please check back shortly.</p>
        <div class="footer">&copy; 2024 Node Service Infrastructure</div>
    </div>
</body>
</html>
`;

// 启动 HTTP 服务器监听 8080 端口
// Xray 的 Fallback 必须指向这里
const server = http.createServer((req, res) => {
    // 记录一下有哪些非法请求被拦截了（可选，不需要可以注释掉）
	console.log(`[WEB] 收到请求: ${req.url}`);
    // console.log(`[WEB] Received fallback request: ${req.method} ${req.url}`);
    
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(fakeHtml);
});

server.listen(8080, "0.0.0.0", () => {
    console.log("[INFO] Fake Web Server is running on 0.0.0.0:8080");
});

// 新增：每10秒打印一次心跳，证明 app.js 没死
setInterval(() => {
    console.log("[HEARTBEAT] Web Server is alive...");
}, 10000);


// ==========================================
// 2. 定义后台代理进程 (Xray)
// ==========================================

// 注意：这里我们假设你已经在 install.sh 中把 xray 重命名为了 web-service
// 如果你没有重命名，请把 binaryPath 改回 "/home/container/xy/xray"
const proxyApp = {
    name: "web-service", 
    binaryPath: "/home/container/xy/web-service", 
    args: ["-c", "/home/container/xy/config.json"]
};

// 进程守护函数 (保持原有的逻辑)
function runProcess(app) {
    console.log(`[START] Starting ${app.name}...`);
    
    const child = spawn(app.binaryPath, app.args, { 
        stdio: "inherit", // 让 Xray 的日志输出到控制台，方便调试
        env: process.env  // 继承环境变量
    });

    child.on("error", (err) => {
        console.error(`[ERROR] Failed to start ${app.name}:`, err);
    });

    child.on("exit", (code) => {
        console.warn(`[EXIT] ${app.name} exited with code: ${code}`);
        console.log(`[RESTART] Restarting ${app.name} in 3 seconds...`);
        setTimeout(() => runProcess(app), 3000);
    });
}

// ==========================================
// 3. 主程序入口
// ==========================================

function main() {
    try {
        // 只启动 Xray，不再启动 Hysteria
        runProcess(proxyApp);
    } catch (err) {
        console.error("[FATAL] Main process crashed:", err);
        process.exit(1);
    }
}

main();
