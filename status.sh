#!/bin/bash

# VDH (Video Downloader Helper) - Status Management Script
# 提供详细的状态检查和服务管理功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 图标定义
ICON_CHECK="✅"
ICON_ERROR="❌"
ICON_WARNING="⚠️"
ICON_INFO="ℹ️"
ICON_RUNNING="🟢"
ICON_STOPPED="🔴"
ICON_QUEUE="📋"
ICON_DOWNLOAD="📥"

print_header() {
    echo -e "${CYAN}$1${NC}"
    echo "$(printf '%*s' "${#1}" '' | tr ' ' '=')"
}

print_status() {
    echo -e "${BLUE}${ICON_INFO}${NC} $1"
}

print_success() {
    echo -e "${GREEN}${ICON_CHECK}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${ICON_WARNING}${NC} $1"
}

print_error() {
    echo -e "${RED}${ICON_ERROR}${NC} $1"
}

# 检查二进制文件
check_binary() {
    print_header "Binary Status"
    
    if command -v vdh &> /dev/null; then
        local binary_path=$(which vdh)
        print_success "Binary found: $binary_path"
        
        # 检查版本
        local version=$(vdh --version 2>/dev/null | head -1 || echo "Unknown")
        echo "  Version: $version"
        
        # 检查权限
        if [ -x "$binary_path" ]; then
            print_success "Binary is executable"
        else
            print_error "Binary is not executable"
        fi
    else
        print_error "Binary 'vdh' not found in PATH"
        echo "  Install with: make install or ./install.sh"
    fi
    echo
}

# 检查 Homebrew 服务状态
check_homebrew_service() {
    print_header "Homebrew Service Status"
    
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not installed"
        echo
        return
    fi
    
    local service_status=$(brew services list | grep vdh || echo "")
    
    if [ -n "$service_status" ]; then
        echo "Service: $service_status"
        
        if echo "$service_status" | grep -q "started"; then
            print_success "Service is running ${ICON_RUNNING}"
        else
            print_warning "Service is not running ${ICON_STOPPED}"
        fi
    else
        print_warning "Service not installed via Homebrew"
        echo "  Install with: brew install local/vdh/vdh"
    fi
    echo
}

# 检查 Socket 状态
check_socket() {
    print_header "Socket Server Status"
    
    local socket_path="/tmp/video_downloader.sock"
    
    if [ -S "$socket_path" ]; then
        print_success "Socket file exists: $socket_path ${ICON_RUNNING}"
        
        # 检查文件权限
        local perms=$(ls -la "$socket_path" | awk '{print $1, $3, $4}')
        echo "  Permissions: $perms"
        
        # 检查文件时间
        local mod_time=$(ls -la "$socket_path" | awk '{print $6, $7, $8}')
        echo "  Modified: $mod_time"
        
    else
        print_error "Socket file not found ${ICON_STOPPED}"
        echo "  Expected: $socket_path"
        echo "  Start server with: vdh server"
    fi
    echo
}

# 检查应用状态和队列
check_app_status() {
    print_header "Application Queue Status"
    
    if [ -S "/tmp/video_downloader.sock" ]; then
        # 尝试获取队列状态
        if command -v vdh &> /dev/null; then
            local status_output=$(vdh status 2>/dev/null || echo "")
            
            if [ -n "$status_output" ]; then
                echo "$status_output" | while read -r line; do
                    if [[ $line == *"STATUS:"* ]]; then
                        echo -e "${GREEN}${ICON_QUEUE}${NC} $line"
                    else
                        echo "  $line"
                    fi
                done
            else
                print_warning "Could not retrieve queue status"
            fi
        else
            print_error "vdh command not available"
        fi
    else
        print_error "Cannot check queue status - server not running"
    fi
    echo
}

# 检查进程
check_processes() {
    print_header "Running Processes"
    
    local processes=$(ps aux | grep -E "(vdh|VideoDownloaderHelper)" | grep -v grep || echo "")
    
    if [ -n "$processes" ]; then
        print_success "Found running processes:"
        echo "$processes" | while read -r line; do
            local pid=$(echo "$line" | awk '{print $2}')
            local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf $i" "}')
            echo "  PID $pid: $cmd"
        done
    else
        print_warning "No related processes found"
    fi
    echo
}

# 检查依赖
check_dependencies() {
    print_header "Dependencies"
    
    # Swift
    if command -v swift &> /dev/null; then
        local swift_version=$(swift --version 2>/dev/null | head -1 || echo "Unknown")
        print_success "Swift: $swift_version"
    else
        print_error "Swift not found"
    fi
    
    # yt-dlp
    if command -v yt-dlp &> /dev/null; then
        local ytdlp_version=$(yt-dlp --version 2>/dev/null || echo "Unknown")
        print_success "yt-dlp: $ytdlp_version"
    else
        print_warning "yt-dlp not found (optional)"
    fi
    
    # Homebrew
    if command -v brew &> /dev/null; then
        local brew_version=$(brew --version 2>/dev/null | head -1 || echo "Unknown")
        print_success "Homebrew: $brew_version"
    else
        print_warning "Homebrew not found (optional)"
    fi
    echo
}

# 检查日志文件
check_logs() {
    print_header "Log Files"
    
    local log_paths=(
        "/usr/local/var/log/vdh/output.log"
        "/usr/local/var/log/vdh/error.log"
        "$(brew --prefix 2>/dev/null)/var/log/vdh/output.log"
        "$(brew --prefix 2>/dev/null)/var/log/vdh/error.log"
    )
    
    local found_logs=false
    
    for log_path in "${log_paths[@]}"; do
        if [ -f "$log_path" ]; then
            found_logs=true
            local size=$(ls -lh "$log_path" | awk '{print $5}')
            local mod_time=$(ls -la "$log_path" | awk '{print $6, $7, $8}')
            print_success "Log found: $log_path ($size, $mod_time)"
            
            # 显示最后几行
            if [ -s "$log_path" ]; then
                echo "  Last 3 lines:"
                tail -3 "$log_path" 2>/dev/null | sed 's/^/    /'
            fi
        fi
    done
    
    if [ "$found_logs" = false ]; then
        print_warning "No log files found"
    fi
    echo
}

# 网络连接检查
check_connections() {
    print_header "Network Connections"
    
    # 检查监听端口
    local socket_connections=$(lsof -U 2>/dev/null | grep video_downloader.sock || echo "")
    
    if [ -n "$socket_connections" ]; then
        print_success "Socket connections found:"
        echo "$socket_connections" | while read -r line; do
            echo "  $line"
        done
    else
        print_warning "No socket connections found"
    fi
    echo
}

# 服务操作
service_action() {
    local action=$1
    print_header "Service $action"
    
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not available"
        return 1
    fi
    
    case $action in
        start)
            if brew services start vdh; then
                print_success "Service started"
                sleep 2
                check_socket
            else
                print_error "Failed to start service"
            fi
            ;;
        stop)
            if brew services stop vdh; then
                print_success "Service stopped"
            else
                print_error "Failed to stop service"
            fi
            ;;
        restart)
            print_status "Stopping service..."
            brew services stop vdh || true
            sleep 1
            print_status "Starting service..."
            if brew services start vdh; then
                print_success "Service restarted"
                sleep 2
                check_socket
            else
                print_error "Failed to restart service"
            fi
            ;;
    esac
}

# 完整状态检查
full_status() {
    echo -e "${CYAN}🎬 VDH (Video Downloader Helper) - System Status${NC}"
    echo "=================================================="
    echo
    
    check_binary
    check_dependencies
    check_homebrew_service
    check_socket
    check_app_status
    check_processes
    check_logs
    check_connections
    
    print_header "Quick Actions"
    echo "  ./status.sh start     # Start service"
    echo "  ./status.sh stop      # Stop service"
    echo "  ./status.sh restart   # Restart service"
    echo "  ./status.sh logs      # Show recent logs"
    echo
}

# 显示最近日志
show_logs() {
    print_header "Recent Logs"
    
    local log_files=(
        "/usr/local/var/log/vdh/output.log"
        "/usr/local/var/log/vdh/error.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo -e "${CYAN}--- $log_file ---${NC}"
            tail -20 "$log_file" 2>/dev/null || echo "Could not read log file"
            echo
        fi
    done
}

# 主函数
main() {
    case "${1:-status}" in
        status|"")
            full_status
            ;;
        start)
            service_action "start"
            ;;
        stop)
            service_action "stop"
            ;;
        restart)
            service_action "restart"
            ;;
        logs)
            show_logs
            ;;
        socket)
            check_socket
            ;;
        queue)
            check_app_status
            ;;
        deps)
            check_dependencies
            ;;
        --help|-h)
            echo "VDH (Video Downloader Helper) - Status Script"
            echo
            echo "Usage: $0 [COMMAND]"
            echo
            echo "Commands:"
            echo "  status     Show full system status (default)"
            echo "  start      Start the service"
            echo "  stop       Stop the service" 
            echo "  restart    Restart the service"
            echo "  logs       Show recent logs"
            echo "  socket     Check socket status only"
            echo "  queue      Check queue status only"
            echo "  deps       Check dependencies only"
            echo "  --help     Show this help"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
