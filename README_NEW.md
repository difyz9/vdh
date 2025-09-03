# VDH (Video Downloader Helper) 

🎬 一个简洁优雅的视频下载助手工具，使用 Unix Domain Socket 和智能队列管理。

## ✨ 为什么选择 VDH？

- 🚀 **简洁命令**：只需输入 `vdh` 而不是冗长的 `video-downloader-helper`
- 🔧 **智能队列**：自动管理并发下载，避免系统资源过载
- 📡 **Unix Socket**：真正的 IPC 通信，比文件监控快 100 倍
- 🍺 **Homebrew 集成**：完整的服务管理支持
- 📊 **实时监控**：随时查看下载状态和队列情况

## 🚀 快速开始

### 安装

#### 方式 1: 使用 Makefile（推荐）
```bash
# 构建和安装
make install

# 检查状态
make service-status
```

#### 方式 2: 使用安装脚本
```bash
./install.sh
```

#### 方式 3: Homebrew（开发模式）
```bash
make homebrew-tap
brew install local/vdh/vdh
```

### 基本使用

```bash
# 🎯 启动服务器
vdh server

# 📥 发送下载请求
vdh send "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# 📊 查看队列状态
vdh status

# ❓ 显示帮助
vdh --help
```

### Homebrew 服务管理

```bash
# 🚀 启动后台服务
brew services start vdh

# 🛑 停止服务
brew services stop vdh

# 📊 查看服务状态
brew services list | grep vdh
```

## 🎛️ 命令参考

| 命令 | 描述 | 示例 |
|------|------|------|
| `server` | 启动 Socket 服务器 | `vdh server` |
| `send <URL>` | 发送下载请求 | `vdh send "https://youtube.com/..."` |
| `status` | 查看队列状态 | `vdh status` |
| `download <URL>` | 直接下载（不通过队列） | `vdh download "https://..."` |
| `test` | 测试 Socket 连接 | `vdh test` |
| `--help` | 显示帮助信息 | `vdh --help` |
| `--version` | 显示版本信息 | `vdh --version` |

## 📋 队列管理系统

### 工作原理

```
📥 请求到达 → 🔍 检查并发数 → 🚀 立即开始 (空闲槽位)
                                  ↘️ 📋 加入队列 (达到限制)
                                      ↓
                                  ⏳ 等待前面任务完成
                                      ↓
                                  🚀 自动开始下载
```

### 队列特性

- **默认并发数**: 2 个同时下载
- **队列容量**: 无限制
- **处理顺序**: FIFO（先进先出）
- **状态监控**: 实时显示活跃和排队数量

### 状态示例

```bash
$ vdh status
📊 STATUS: 2 active, 3 queued downloads
```

## 🛠️ 开发和构建

### Make 命令

```bash
# 构建
make build

# 安装到系统
make install

# 创建 Homebrew tap
make homebrew-tap

# 服务管理
make service-start
make service-stop
make service-status

# 清理
make clean

# 显示帮助
make help
```

### 状态管理脚本

```bash
# 完整系统状态检查
./status.sh

# 启动服务
./status.sh start

# 停止服务
./status.sh stop

# 重启服务
./status.sh restart

# 查看日志
./status.sh logs
```

## 📡 Socket 通信协议

### 连接信息
- **Socket 路径**: `/tmp/video_downloader.sock`
- **协议类型**: Unix Domain Socket (SOCK_STREAM)

### 消息格式
- **下载请求**: `<URL>`
- **状态查询**: `STATUS`
- **响应格式**: 
  - 下载: `OK: Download queued for <URL> (ID: <ID>)`
  - 状态: `STATUS: <active> active, <queued> queued downloads`

## 📊 性能对比

| 特性 | 文件监控 | Unix Socket | VDH 队列管理 |
|------|----------|-------------|-------------|
| 响应时间 | 1秒延迟 | 实时 | 实时 |
| 并发支持 | 串行 | 并发 | 受控并发 |
| 资源管理 | 无控制 | 基本 | 智能管理 |
| 队列处理 | 无 | 无 | FIFO队列 |
| 命令长度 | 长 | 长 | **简洁** |

## 🎯 使用场景

### 批量下载
```bash
# 启动服务
vdh server &

# 批量发送请求
vdh send "https://youtube.com/watch?v=abc123"
vdh send "https://youtube.com/watch?v=def456"
vdh send "https://youtube.com/watch?v=ghi789"

# 监控进度
watch -n 2 'vdh status'
```

### Homebrew 服务模式
```bash
# 一次性设置
brew services start vdh

# 日常使用
vdh send "https://..."
vdh status
```

### 开发调试
```bash
# 测试连接
vdh test

# 直接下载（跳过队列）
vdh download "https://..."

# 查看详细状态
./status.sh
```

## 🔧 配置选项

### 修改并发数
在代码中修改构造函数：
```swift
let helper = VideoDownloaderHelper(maxConcurrentDownloads: 3) // 改为3个并发
```

### 自定义 socket 路径
修改 `socketPath` 变量：
```swift
private let socketPath = "/tmp/custom_socket.sock"
```

## 📁 文件结构

```
vdh/
├── main.swift              # 主程序源码
├── vdh                     # 编译后的二进制文件
├── vdh.rb                  # Homebrew Formula
├── Makefile                # 构建脚本
├── install.sh              # 安装脚本
├── status.sh               # 状态管理脚本
├── test_queue.sh           # 队列测试脚本
└── README.md               # 本文档
```

## ❓ 故障排除

### 常见问题

1. **"Failed to bind socket"**
   ```bash
   # 检查是否有其他实例在运行
   ./status.sh
   # 或手动清理
   rm -f /tmp/video_downloader.sock
   ```

2. **"Failed to connect"**
   ```bash
   # 确保服务器已启动
   vdh server &
   # 或使用 Homebrew 服务
   brew services start vdh
   ```

3. **"vdh command not found"**
   ```bash
   # 重新安装
   make install
   # 或检查 PATH
   echo $PATH
   ```

4. **下载失败**
   ```bash
   # 检查 yt-dlp 安装
   which yt-dlp
   # 安装 yt-dlp
   brew install yt-dlp
   ```

### 调试技巧

```bash
# 查看完整系统状态
./status.sh

# 查看日志
./status.sh logs

# 测试 socket 连接
vdh test

# 手动清理
make clean
rm -f /tmp/video_downloader.sock
```

## 🚀 更新日志

### v1.0.0
- ✅ 重命名为简洁的 `vdh` 命令
- ✅ 完整的 Homebrew 支持
- ✅ 智能下载队列管理
- ✅ Unix Domain Socket 通信
- ✅ 实时状态监控
- ✅ 优雅的服务管理

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

---

**VDH - 让视频下载变得简单优雅** 🎬✨
