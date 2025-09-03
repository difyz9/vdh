#!/bin/bash

# 编译 Helper Tool 的脚本
echo "编译 VideoDownloaderHelper..."

# 检查 Swift 编译器
if ! command -v swiftc &> /dev/null; then
    echo "错误: 需要安装 Xcode 或 Command Line Tools"
    echo "请运行: xcode-select --install"
    exit 1
fi

# 编译
swiftc -o VideoDownloaderHelper main.swift

if [ $? -eq 0 ]; then
    echo "编译成功!"
    echo "可执行文件: ./VideoDownloaderHelper"
    echo ""
    echo "使用方法:"
    echo "  ./VideoDownloaderHelper server              # 启动服务器模式"
    echo "  ./VideoDownloaderHelper download <URL>      # 直接下载"
    echo ""
    echo "测试下载 (需要先安装 yt-dlp):"
    echo "  brew install yt-dlp"
    echo "  ./VideoDownloaderHelper download 'https://www.youtube.com/watch?v=ILgEIHtJLVo'"
else
    echo "编译失败!"
    exit 1
fi
