#!/bin/bash

# VDH (Video Downloader Helper) - Installation Script
# 支持多种安装方式：直接安装、Homebrew、开发模式

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

# 检查依赖
check_dependencies() {
    print_status "Checking dependencies..."
    
    # 检查 Swift
    if ! command -v swift &> /dev/null; then
        print_error "Swift is not installed. Please install Xcode or Swift toolchain."
        exit 1
    fi
    print_success "Swift found: $(swift --version | head -1)"
    
    # 检查 yt-dlp (可选)
    if command -v yt-dlp &> /dev/null; then
        print_success "yt-dlp found: $(yt-dlp --version)"
    else
        print_warning "yt-dlp not found. It's recommended for video downloading."
        echo "  Install with: brew install yt-dlp"
    fi
    
    # 检查 Homebrew (可选)
    if command -v brew &> /dev/null; then
        print_success "Homebrew found: $(brew --version | head -1)"
        HOMEBREW_AVAILABLE=true
    else
        print_warning "Homebrew not found. Manual installation will be used."
        HOMEBREW_AVAILABLE=false
    fi
}

# 构建应用
build_app() {
    print_status "Building VDH (Video Downloader Helper)..."
    
    if [ ! -f "main.swift" ]; then
        print_error "main.swift not found in current directory"
        exit 1
    fi
    
    swiftc main.swift -o vdh
    print_success "Build completed: vdh"
}

# 直接安装
install_direct() {
    print_status "Installing vdh to /usr/local/bin..."
    
    sudo cp vdh /usr/local/bin/
    sudo chmod +x /usr/local/bin/vdh
    
    print_success "Installation completed!"
    print_status "Binary installed at: /usr/local/bin/vdh"
}

# Homebrew 安装
install_homebrew() {
    print_status "Setting up Homebrew installation..."
    
    # 创建本地 tap
    TAP_DIR="$HOME/.homebrew-tap"
    mkdir -p "$TAP_DIR/Formula"
    cp vdh.rb "$TAP_DIR/Formula/"
    
    print_success "Local tap created at: $TAP_DIR"
    
    # 添加 tap
    if brew tap local/vdh "$TAP_DIR" 2>/dev/null; then
        print_success "Tap added successfully"
    else
        print_warning "Tap might already exist"
    fi
    
    # 安装包
    if brew install local/vdh/vdh; then
        print_success "Homebrew installation completed!"
    else
        print_error "Homebrew installation failed"
        return 1
    fi
}

# 服务管理
setup_service() {
    if [ "$HOMEBREW_AVAILABLE" = true ] && command -v vdh &> /dev/null; then
        print_status "Setting up background service..."
        
        read -p "Do you want to start the service automatically? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew services start vdh
            print_success "Service started and will run automatically"
        else
            print_status "Service not started. You can start it later with:"
            echo "  brew services start vdh"
        fi
    fi
}

# 测试安装
test_installation() {
    print_status "Testing installation..."
    
    if command -v vdh &> /dev/null; then
        print_success "Command 'vdh' is available"
        
        # 测试版本
        vdh --version
        
        # 测试帮助
        print_status "Testing help command..."
        vdh --help | head -3
        
        print_success "Installation test passed!"
        return 0
    else
        print_error "Installation test failed - command not found"
        return 1
    fi
}

# 显示使用说明
show_usage() {
    echo
    print_success "Installation completed! Here's how to use VDH:"
    echo
    echo "📖 Basic Commands:"
    echo "  vdh server          # Start server"
    echo "  vdh send '<URL>'    # Send download request"
    echo "  vdh status          # Check queue status"
    echo "  vdh --help          # Show help"
    echo
    echo "🍺 Homebrew Service Management:"
    echo "  brew services start vdh    # Start service"
    echo "  brew services stop vdh     # Stop service"
    echo "  brew services list | grep vdh    # Check status"
    echo
    echo "📝 Example Workflow:"
    echo "  1. Start service: brew services start vdh"
    echo "  2. Send request: vdh send 'https://youtube.com/watch?v=...'"
    echo "  3. Check status: vdh status"
    echo
    echo "📁 Configuration and logs:"
    echo "  Config: /usr/local/etc/vdh/config.json"
    echo "  Logs: /usr/local/var/log/vdh/"
    echo
}

# 主安装流程
main() {
    echo "🎬 VDH (Video Downloader Helper) - Installation Script"
    echo "====================================================="
    echo
    
    # 检查依赖
    check_dependencies
    echo
    
    # 构建
    build_app
    echo
    
    # 选择安装方式
    if [ "$HOMEBREW_AVAILABLE" = true ]; then
        echo "Choose installation method:"
        echo "  1) Homebrew (recommended)"
        echo "  2) Direct installation"
        echo
        read -p "Enter your choice (1-2): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                if install_homebrew; then
                    setup_service
                fi
                ;;
            2)
                install_direct
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    else
        install_direct
    fi
    
    echo
    
    # 测试安装
    if test_installation; then
        show_usage
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# 处理命令行参数
case "${1:-}" in
    --help|-h)
        echo "VDH (Video Downloader Helper) - Installation Script"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help"
        echo "  --homebrew     Force Homebrew installation"
        echo "  --direct       Force direct installation"
        echo "  --build-only   Only build, don't install"
        echo
        exit 0
        ;;
    --homebrew)
        check_dependencies
        build_app
        install_homebrew
        setup_service
        test_installation && show_usage
        ;;
    --direct)
        check_dependencies
        build_app
        install_direct
        test_installation && show_usage
        ;;
    --build-only)
        check_dependencies
        build_app
        print_success "Build completed. Binary: ./vdh"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
