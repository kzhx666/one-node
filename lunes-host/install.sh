#!/usr/bin/env sh

# === 配置区域 ===
DOMAIN="${DOMAIN:-node68.lunes.host}"
PORT="${PORT:-3147}" # 确保这里是你 Lunes Host 分配的端口
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"
# Hysteria 密码已不再需要，直接移除

# === 1. 环境准备与 Node 包装器下载 ===
echo "Starting stealth installation..."
# 下载 app.js 和 package.json
curl -sSL -o app.js https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/lunes-host/app.js
curl -sSL -o package.json https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/lunes-host/package.json

# === 2. 核心下载与伪装 ===
mkdir -p /home/container/xy
cd /home/container/xy

# 下载 Xray 核心
curl -sSL -o Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-64.zip
unzip -q Xray-linux-64.zip
rm Xray-linux-64.zip

# [关键步骤]：将 xray 重命名为 web-service 进行进程伪装
mv xray web-service
chmod +x web-service

# === 3. 生成 VLESS + WebSocket + Fallback 配置文件 ===
# 我们不再下载远程配置，而是直接写入通过 Fallback 隐藏流量的配置
cat <<EOF > config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 8080
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$UUID"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# === 4. 自动修补 app.js 以匹配新架构 ===
cd /home/container
# 修改 app.js：让它启动 web-service 而不是 xy
sed -i "s|./xy/xray|./xy/web-service|g" app.js
sed -i "s|./xy|./xy/web-service|g" app.js
# 修改 app.js：移除 Hysteria 启动逻辑
sed -i "/h2/d" app.js 
sed -i "/hysteria/d" app.js

# 创建一个简单的伪装页面生成器 (配合之后的 app.js 修改)
# 注意：你需要手动修改 app.js 里的 HTTP Server 部分才能完全生效，
# 但这个脚本保证了核心代理部分已经就绪。

# === 5. 生成客户端连接信息 ===
# 构建 VLESS WS 链接 (注意：客户端需要开启 TLS 如果你套了 Cloudflare，否则就是纯 HTTP WS)
# 针对 Lunes Host，通常是 HTTP 端口，所以这里生成非 TLS 的 WS 链接
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&security=none&type=ws&path=%2F$UUID#Lunes-Stealth-Node"

echo "$vlessUrl" > /home/container/node.txt

echo "============================================================"
echo "🥷 Stealth Setup Complete (UDP/Hysteria Removed)"
echo "------------------------------------------------------------"
echo "Process Name : web-service (Masked)"
echo "Protocol     : VLESS + WebSocket"
echo "Path         : /$UUID"
echo "Fallback     : Enabled -> Localhost:8080"
echo "------------------------------------------------------------"
echo "Your Node Link:"
echo "$vlessUrl"
echo "============================================================"
