#!/bin/bash
# install-local.sh - 本地安装 Video Downloader Helper

set -e

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/video-downloader-helper"
LOG_DIR="$HOME/.local/share/video-downloader-helper/logs"

echo "🚀 安装 Video Downloader Helper..."

# 检查依赖
if ! command -v swift &> /dev/null; then
    echo "❌ 错误: 需要安装 Xcode 或 Command Line Tools"
    echo "请运行: xcode-select --install"
    exit 1
fi

if ! command -v yt-dlp &> /dev/null; then
    echo "📦 安装 yt-dlp..."
    if command -v brew &> /dev/null; then
        brew install yt-dlp
    else
        echo "❌ 请先安装 Homebrew 或手动安装 yt-dlp"
        exit 1
    fi
fi

# 检查源码文件
if [ ! -f "main.swift" ]; then
    echo "❌ 错误: 找不到 main.swift 文件"
    echo "请确保在包含 main.swift 的目录中运行此脚本"
    exit 1
fi

# 编译程序
echo "🔨 编译 Helper Tool..."
swiftc -o VideoDownloaderHelper main.swift

# 创建目录
echo "📁 创建配置目录..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"

# 安装二进制文件
echo "📦 安装到系统路径..."
sudo cp VideoDownloaderHelper "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/VideoDownloaderHelper"

# 安装配置文件
if [ -f "Helper.entitlements" ]; then
    cp Helper.entitlements "$CONFIG_DIR/"
fi

# 创建启动脚本
sudo tee "$INSTALL_DIR/video-downloader-helper" > /dev/null << 'EOF'
#!/bin/bash
exec VideoDownloaderHelper "$@"
EOF

sudo chmod +x "$INSTALL_DIR/video-downloader-helper"

# 创建默认配置文件
cat > "$CONFIG_DIR/config.json" << EOF
{
  "server": {
    "socket_path": "/tmp/video_downloader.sock",
    "log_level": "info"
  },
  "downloader": {
    "yt_dlp_path": "$(which yt-dlp)",
    "output_directory": "$HOME/Downloads/VideoDownloader",
    "proxy": "http://127.0.0.1:7890",
    "cookies_from_browser": "chrome"
  }
}
EOF

# 创建 LaunchAgent 配置 (可选)
cat > "$HOME/Library/LaunchAgents/com.local.video-downloader-helper.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.video-downloader-helper</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/VideoDownloaderHelper</string>
        <string>server</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/output.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/error.log</string>
    <key>WorkingDirectory</key>
    <string>$HOME</string>
</dict>
</plist>
EOF

# 清理
rm -f VideoDownloaderHelper

echo "✅ 安装完成!"
echo ""
echo "📋 使用方法:"
echo "  启动服务: video-downloader-helper server"
echo "  下载视频: video-downloader-helper download <URL>"
echo "  开机启动: launchctl load ~/Library/LaunchAgents/com.local.video-downloader-helper.plist"
echo "  停止服务: launchctl unload ~/Library/LaunchAgents/com.local.video-downloader-helper.plist"
echo ""
echo "📂 配置文件: $CONFIG_DIR/config.json"
echo "📊 日志目录: $LOG_DIR"
echo "📄 LaunchAgent: ~/Library/LaunchAgents/com.local.video-downloader-helper.plist"
echo ""
echo "🔧 下一步："
echo "1. 编辑配置文件设置代理和其他选项"
echo "2. 运行: video-downloader-helper server"
echo "3. 测试: video-downloader-helper download 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
