#!/bin/bash

# VDH (Video Downloader Helper) - Local Installation Script
# 简化版本：编译并安装到本地系统环境目录

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色消息
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要依赖
check_swift() {
    print_status "检查 Swift 编译器..."
    if ! command -v swift &> /dev/null; then
        print_error "Swift 编译器未找到，请安装 Xcode 或 Swift 工具链"
        echo "  安装方法："
        echo "  1. 安装 Xcode: https://developer.apple.com/xcode/"
        echo "  2. 或安装 Swift 工具链: https://swift.org/download/"
        exit 1
    fi
    print_success "Swift 编译器版本: $(swift --version | head -1)"
}

# 检查源文件
check_source() {
    print_status "检查源代码文件..."
    if [ ! -f "main.swift" ]; then
        print_error "main.swift 文件不存在于当前目录"
        echo "请确保在项目根目录运行此脚本"
        exit 1
    fi
    print_success "源文件检查完成"
}

# 编译项目
build_project() {
    print_status "编译 VDH 项目..."
    
    # 清理之前的构建
    if [ -f "vdh" ]; then
        rm -f vdh
        print_status "清理之前的构建文件"
    fi
    
    # 编译 Swift 项目
    swiftc main.swift -o vdh -O
    
    if [ ! -f "vdh" ]; then
        print_error "编译失败"
        exit 1
    fi
    
    print_success "编译完成: vdh"
}

# 检查安装目录
check_install_dir() {
    INSTALL_DIR="/usr/local/bin"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        print_status "创建安装目录: $INSTALL_DIR"
        sudo mkdir -p "$INSTALL_DIR"
    fi
    
    if [ ! -w "$INSTALL_DIR" ]; then
        print_status "需要管理员权限安装到系统目录"
        return 1
    fi
    return 0
}

# 安装到系统目录
install_to_system() {
    INSTALL_DIR="/usr/local/bin"
    print_status "安装 vdh 到 $INSTALL_DIR ..."
    
    # 备份现有版本（如果存在）
    if [ -f "$INSTALL_DIR/vdh" ]; then
        print_warning "发现现有的 vdh 安装，创建备份..."
        sudo mv "$INSTALL_DIR/vdh" "$INSTALL_DIR/vdh.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 复制新版本
    sudo cp vdh "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/vdh"
    
    print_success "安装完成！"
}

# 创建用户目录
setup_user_directories() {
    print_status "设置用户配置目录..."
    
    VDH_DIR="$HOME/.vdh"
    if [ ! -d "$VDH_DIR" ]; then
        mkdir -p "$VDH_DIR"
        print_success "创建目录: $VDH_DIR"
    fi
    
    # 设置权限
    chmod 755 "$VDH_DIR"
    
    print_status "用户目录设置完成"
}

# 测试安装
test_installation() {
    print_status "测试安装..."
    
    # 检查命令是否可用
    if ! command -v vdh &> /dev/null; then
        print_error "安装测试失败 - vdh 命令未找到"
        echo "可能需要重新打开终端或运行: source ~/.zshrc"
        return 1
    fi
    
    print_success "命令 'vdh' 可用"
    
    # 测试基本功能
    print_status "测试基本功能..."
    if vdh --help > /dev/null 2>&1; then
        print_success "帮助命令正常"
    else
        print_warning "帮助命令可能有问题，但安装已完成"
    fi
    
    print_success "安装测试通过！"
}

# 显示使用说明
show_usage_guide() {
    echo
    echo "🎉 VDH 安装成功！"
    echo "==================="
    echo
    echo "📖 常用命令："
    echo "  vdh start                    # 启动后台服务"
    echo "  vdh stop                     # 停止后台服务"
    echo "  vdh status                   # 查看服务状态"
    echo "  vdh download \"<URL>\"         # 下载视频"
    echo "  vdh queue                    # 查看下载队列"
    echo "  vdh config show              # 显示配置"
    echo "  vdh --help                   # 显示帮助"
    echo
    echo "🔧 配置管理："
    echo "  vdh config edit              # 编辑配置文件"
    echo "  vdh config reload            # 重新加载配置"
    echo "  vdh config reset             # 重置为默认配置"
    echo
    echo "📁 重要路径："
    echo "  配置文件: ~/.vdh/config.yaml"
    echo "  数据库:   ~/.vdh/vdh.db"
    echo "  日志:     ~/.vdh/vdh.log"
    echo
    echo "💡 快速开始："
    echo "  1. 启动服务: vdh start"
    echo "  2. 下载视频: vdh download \"https://www.youtube.com/watch?v=...\""
    echo "  3. 查看状态: vdh status"
    echo
}

# 主安装流程
main() {
    echo "🎬 VDH 本地安装脚本"
    echo "==================="
    echo
    
    # 检查依赖
    check_swift
    check_source
    echo
    
    # 编译项目
    build_project
    echo
    
    # 设置用户目录
    setup_user_directories
    echo
    
    # 安装到系统
    if check_install_dir; then
        cp vdh /usr/local/bin/
        chmod +x /usr/local/bin/vdh
        print_success "安装完成（无需 sudo）"
    else
        install_to_system
    fi
    echo
    
    # 测试安装
    if test_installation; then
        show_usage_guide
    else
        print_error "安装验证失败"
        exit 1
    fi
}

# 处理命令行参数
case "${1:-}" in
    --help|-h)
        echo "VDH 本地安装脚本"
        echo
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  --help, -h     显示此帮助"
        echo "  --build-only   仅编译，不安装"
        echo "  --force        强制重新安装"
        echo
        exit 0
        ;;
    --build-only)
        check_swift
        check_source
        build_project
        print_success "编译完成。可执行文件: ./vdh"
        ;;
    --force)
        print_status "强制重新安装模式"
        main
        ;;
    "")
        main
        ;;
    *)
        print_error "未知选项: $1"
        echo "使用 --help 查看用法"
        exit 1
        ;;
esac