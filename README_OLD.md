# VideoDownloaderHelper - Unix Socket 版本

这是一个使用真正 Unix Domain Socket 的视频下载助手工具，支持并发控制和下载队列管理。

## 功能特性

- ✅ 真正的 Unix Domain Socket 通信
- ✅ 多客户端并发支持
- ✅ **智能下载队列管理**
- ✅ **并发下载控制（默认最大2个）**
- ✅ **FIFO 队列处理**
- ✅ **实时状态查询**
- ✅ 优雅的信号处理和关闭
- ✅ 客户端/服务器架构
- ✅ 内置测试功能

## 编译

```bash
swiftc main.swift -o VideoDownloaderHelper
```

## 使用方法

### 1. 启动 Socket 服务器

```bash
./VideoDownloaderHelper server
```

服务器将创建 Unix socket 文件：`/tmp/video_downloader.sock`

### 2. 发送下载请求

在另一个终端中：

```bash
./VideoDownloaderHelper send "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

### 3. 查看队列状态

```bash
./VideoDownloaderHelper status
```

输出示例：
```
📊 STATUS: 2 active, 3 queued downloads
```

### 4. 直接下载（不通过 socket）

```bash
./VideoDownloaderHelper download "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

### 5. 测试 Socket 通信

```bash
./VideoDownloaderHelper test
```

## 队列管理系统

### 并发控制

- **默认最大并发数**: 2个同时下载
- **队列容量**: 无限制
- **处理顺序**: FIFO（先进先出）

### 工作流程

1. **请求接收**: 客户端发送下载URL
2. **队列分配**: 
   - 如果有空闲槽位 → 立即开始下载
   - 如果达到并发限制 → 加入等待队列
3. **状态跟踪**: 实时监控活跃和排队的下载
4. **自动处理**: 下载完成后自动处理队列中的下一个任务

### 状态信息

每个下载任务都包含：
- 📝 **任务ID**: 唯一标识符
- 🎬 **URL信息**: 下载链接
- 📊 **队列状态**: 活跃/排队数量
- ⏱️ **处理时间**: 开始和完成时间
- ✅/❌ **结果状态**: 成功或失败

## Socket 通信协议

- **连接**: 客户端连接到 `/tmp/video_downloader.sock`
- **下载请求**: `<URL>`
- **状态查询**: `STATUS`
- **响应格式**: 
  - 下载: `OK: Download queued for <URL> (ID: <ID>)`
  - 状态: `STATUS: <active> active, <queued> queued downloads`

## 示例工作流

### 基本使用
```bash
# 终端 1: 启动服务器
./VideoDownloaderHelper server

# 终端 2: 发送下载请求
./VideoDownloaderHelper send "https://youtube.com/watch?v=abc123"
./VideoDownloaderHelper send "https://youtube.com/watch?v=def456"
./VideoDownloaderHelper send "https://youtube.com/watch?v=ghi789"

# 查看队列状态
./VideoDownloaderHelper status
```

### 批量下载测试
```bash
# 运行队列测试脚本
./test_queue.sh
```

## 技术实现

### 队列管理架构

1. **并发控制**: 使用 `DispatchSemaphore` 限制最大并发数
2. **线程安全**: 使用 `NSLock` 保护队列操作
3. **异步处理**: 使用 `DispatchQueue` 进行后台下载
4. **状态同步**: 实时更新活跃和排队计数

### 性能优化

| 特性 | 文件监控 | Unix Socket | 队列管理 |
|------|----------|-------------|----------|
| 响应时间 | 1秒延迟 | 实时 | 实时 |
| 并发支持 | 串行 | 并发 | 受控并发 |
| 资源管理 | 无控制 | 基本 | 智能管理 |
| 队列处理 | 无 | 无 | FIFO队列 |

## 配置选项

### 修改最大并发数

在代码中修改构造函数参数：
```swift
let helper = VideoDownloaderHelper(maxConcurrentDownloads: 3) // 改为3个并发
```

### 自定义 socket 路径

修改 `socketPath` 变量：
```swift
private let socketPath = "/tmp/custom_socket.sock"
```

## 错误排查

1. **"Failed to bind socket"**: 检查是否已有实例在运行
2. **"Failed to connect"**: 确保服务器已启动
3. **"yt-dlp not found"**: 安装 yt-dlp 到指定路径
4. **队列阻塞**: 检查下载进程是否卡住
5. **权限问题**: 确保对 `/tmp` 目录有写权限

## 监控和调试

### 日志信息说明

- 📥 `Added to queue`: 任务已加入队列
- 🚀 `Starting download`: 开始下载
- 📊 `Queue status`: 当前队列状态
- ✅ `Download completed`: 下载完成
- ❌ `Download failed`: 下载失败

### 状态监控

```bash
# 持续监控队列状态
watch -n 2 './VideoDownloaderHelper status'
```

## 停止服务器

使用 `Ctrl+C` 或发送 SIGTERM 信号，服务器会优雅关闭并清理 socket 文件。
