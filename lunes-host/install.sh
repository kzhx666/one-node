#!/usr/bin/env sh

# === 配置区域 (在这里直接填好，不用环境变量了) ===
DOMAIN="node1.lunes.host"     # 你的域名
PORT="2005"                    # 你的端口
UUID="5f9e5ea6-f3f6-4303-9e91-a2d5587f913b" # 你的UUID

# === 1. 核心下载与伪装 ===
echo "Starting stealth installation..."
mkdir -p /home/container/xy
cd /home/container/xy

# 下载 Xray 核心 (必须步骤)
echo "Downloading Core..."
curl -sSL -o Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-64.zip
unzip -q Xray-linux-64.zip
rm Xray-linux-64.zip

# 重命名伪装
mv xray web-service
chmod +x web-service

# === 2. 生成 VLESS + WebSocket + Fallback 配置 ===
echo "Generating Config..."
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

# === 3. 生成节点链接文件 ===
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&security=none&type=ws&path=%2F$UUID#Lunes-Stealth"
echo "$vlessUrl" > /home/container/node.txt

echo "============================================================"
echo "✅ Installation Done!"
echo "Please go to Console and click START"
echo "============================================================"
