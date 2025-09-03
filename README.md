# VDH (Video Downloader Helper) v2.0.0

🎬 一个专业的视频下载助手工具，配备 SQLite3 数据库、智能队列管理和 Unix Domain Socket 通信。

## ✨ 新版本亮点

- 🗃️ **SQLite3 数据库**：持久化任务存储，服务器重启不丢失数据
- 🏷️ **12位随机ID**：每个任务自动分配唯一的12位随机字符串标识符
- 📊 **任务状态跟踪**：6种状态精确管理任务生命周期
- 🔍 **任务查询系统**：通过ID快速查询任务详情和状态
- 🚀 **队列恢复**：服务器重启后自动恢复未完成任务
- 📈 **统计面板**：详细的任务统计和历史记录

## 🎯 核心特性

- 🚀 **简洁命令**：只需输入 `vdh` 而不是冗长的 `video-downloader-helper`
- 🔧 **智能队列**：自动管理并发下载，避免系统资源过载
- 📡 **Unix Socket**：真正的 IPC 通信，比文件监控快 100 倍
- 🍺 **Homebrew 集成**：完整的服务管理支持
- 📊 **实时监控**：随时查看下载状态和队列情况
- 🗃️ **数据持久化**：SQLite3 数据库确保数据安全

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

# 📥 发送下载请求 (返回12位任务ID)
vdh -i "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
# 输出: OK: Task added with ID abc123def456

# 🔍 查询特定任务状态
vdh task abc123def456

# 📋 查看最近任务列表
vdh list

# 📊 查看队列状态和统计
vdh status
vdh stats

# 🧹 清理旧任务记录
vdh cleanup

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
| `input <URL>`, `-i <URL>` | 发送下载请求 (返回任务ID) | `vdh -i "https://youtube.com/..."` |
| `task <ID>` | 查询特定任务详情 | `vdh task abc123def456` |
| `list`, `ls` | 查看最近任务列表 | `vdh list` |
| `status` | 查看队列状态 | `vdh status` |
| `stats` | 查看任务统计信息 | `vdh stats` |
| `cleanup` | 清理30天前的旧任务 | `vdh cleanup` |
| `download <URL>`, `-d <URL>` | 直接下载（不通过队列） | `vdh -d "https://..."` |
| `test` | 测试 Socket 连接 | `vdh test` |
| `--help` | 显示帮助信息 | `vdh --help` |
| `--version` | 显示版本信息 | `vdh --version` |

## 🗃️ 数据库和任务管理

### 任务状态生命周期

```
📝 pending → ⏳ queued → ⬇️ downloading → ✅ completed
                                       ↘️ ❌ failed
                                       ↘️ 🚫 cancelled
```

### 状态说明

| 状态 | 图标 | 描述 |
|------|------|------|
| `pending` | ⏸️ | 任务已创建，等待加入队列 |
| `queued` | ⏳ | 任务已排队，等待开始下载 |
| `downloading` | ⬇️ | 正在下载中 |
| `completed` | ✅ | 下载成功完成 |
| `failed` | ❌ | 下载失败 |
| `cancelled` | 🚫 | 任务被取消 |

### 任务ID系统

- **格式**: 12位随机字符串 (例: `abc123DEF456`)
- **字符集**: 数字和大小写字母
- **唯一性**: 每个任务都有唯一标识符
- **持久性**: 存储在SQLite数据库中

### 数据库位置

- **路径**: `~/Documents/VideoDownloader/tasks.db`
- **类型**: SQLite3 数据库
- **表结构**: 
  ```sql
  CREATE TABLE tasks (
      id TEXT PRIMARY KEY,              -- 12位随机字符串
      url TEXT NOT NULL,               -- 视频URL
      status TEXT NOT NULL DEFAULT 'pending',  -- 任务状态
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      started_at DATETIME,             -- 开始下载时间
      completed_at DATETIME,           -- 完成时间
      error_message TEXT,              -- 错误信息
      file_path TEXT                   -- 下载文件路径
  );
  ```

## 📋 队列管理系统

### 工作原理

```
📥 请求到达 → �️ 创建任务(pending) → 📋 加入队列(queued) 
                                               ↓
🔍 检查并发数 → 🚀 立即开始(downloading) ← ⏳ 等待前面任务完成
     ↓
✅ 完成/❌ 失败 → 🗃️ 更新数据库状态 → � 处理下一个任务
```

### 队列特性

- **默认并发数**: 2 个同时下载
- **队列容量**: 无限制
- **处理顺序**: FIFO（先进先出）
- **状态监控**: 实时显示活跃和排队数量
- **数据持久化**: 任务信息存储在SQLite数据库
- **断点恢复**: 服务器重启后自动恢复未完成任务

### 状态示例

```bash
$ vdh status
📊 QUEUE: 2 active, 3 queued | TOTAL: 15 tasks | PENDING: 2 | DOWNLOADING: 2 | COMPLETED: 8 | FAILED: 3

$ vdh stats
📊 Task Statistics:
  ⏸️ Pending: 2
  ⏳ Queued: 3
  ⬇️ Downloading: 2
  ✅ Completed: 8
  ❌ Failed: 3
  🚫 Cancelled: 0
  📋 Total: 18

$ vdh task abc123def456
TASK abc123def456: COMPLETED
URL: https://www.youtube.com/watch?v=example
Created: 2025-09-03 08:30:15
Started: 2025-09-03 08:30:20
Completed: 2025-09-03 08:32:45
File: ~/Downloads/VideoDownloader/example.mp4
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
- **任务查询**: `TASK:<12位ID>`
- **状态查询**: `STATUS`
- **任务列表**: `LIST`

### 响应格式
- **下载成功**: `OK: Task added with ID <12位ID>`
- **任务详情**: 
  ```
  TASK <ID>: <STATUS>
  URL: <URL>
  Created: <时间戳>
  Started: <时间戳>
  Completed: <时间戳>
  File: <文件路径>
  Error: <错误信息>
  ```
- **队列状态**: `QUEUE: <active> active, <queued> queued | TOTAL: <total> tasks | <STATUS>: <count>`
- **任务列表**: 
  ```
  RECENT TASKS (<count>):
  <emoji> ID:<12位ID> [<STATUS>] <URL>
  ...
  ```

## 📊 性能对比

| 特性 | 文件监控 | Unix Socket | VDH v1.0 | **VDH v2.0** |
|------|----------|-------------|----------|-------------|
| 响应时间 | 1秒延迟 | 实时 | 实时 | **实时** |
| 并发支持 | 串行 | 并发 | 受控并发 | **受控并发** |
| 资源管理 | 无控制 | 基本 | 智能管理 | **智能管理** |
| 队列处理 | 无 | 无 | FIFO队列 | **FIFO队列** |
| 数据持久化 | ❌ | ❌ | ❌ | **✅ SQLite3** |
| 任务查询 | ❌ | ❌ | 基础 | **✅ 12位ID查询** |
| 状态跟踪 | ❌ | ❌ | 基础 | **✅ 6种状态** |
| 断点恢复 | ❌ | ❌ | ❌ | **✅ 自动恢复** |
| 命令长度 | 长 | 长 | 简洁 | **简洁** |

## 🎯 使用场景

### 日常下载管理
```bash
# 启动服务（一次性设置）
brew services start vdh

# 添加下载任务
vdh -i "https://youtube.com/watch?v=abc123"
# 输出: OK: Task added with ID def456ghi789

# 查询任务状态
vdh task def456ghi789

# 查看所有任务
vdh list

# 定期清理
vdh cleanup
```

### 批量下载
```bash
# 启动服务
vdh server &

# 批量发送请求
vdh -i "https://youtube.com/watch?v=abc123"
vdh -i "https://youtube.com/watch?v=def456"
vdh input "https://youtube.com/watch?v=ghi789"

# 监控进度
watch -n 2 'vdh status'
```

### Homebrew 服务模式
```bash
# 一次性设置
brew services start vdh

# 日常使用
vdh -i "https://..."
vdh status
```

### 开发调试
```bash
# 测试连接
vdh test

# 直接下载（跳过队列）
vdh -d "https://..."

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
├── main.swift              # 主程序源码 (1100+ 行)
├── vdh                     # 编译后的二进制文件
├── vdh.rb                  # Homebrew Formula
├── Makefile                # 构建脚本
├── install.sh              # 安装脚本
├── status.sh               # 状态管理脚本
├── test_queue.sh           # 队列测试脚本
├── test_socket.sh          # Socket通信测试
├── video_downloader.db     # SQLite3 数据库文件
└── README.md               # 本文档
```

### 核心组件

- **DatabaseManager**: SQLite3 数据库管理类
- **VideoDownloaderHelper**: 主服务类，处理队列和下载
- **TaskStatus**: 任务状态枚举 (6种状态)
- **DownloadTask**: 任务数据结构
- **Socket Communication**: Unix Domain Socket 服务器

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
   
   # 查看失败任务详情
   vdh task <task_id>
   ```

5. **数据库问题**
   ```bash
   # 检查数据库文件
   ls -la ~/video_downloader.db
   
   # 修复数据库
   sqlite3 ~/video_downloader.db "PRAGMA integrity_check;"
   
   # 重置数据库（注意：会丢失所有数据）
   rm ~/video_downloader.db
   vdh server &  # 重新创建数据库
   ```

6. **任务ID查询失败**
   ```bash
   # 检查任务ID格式（必须是12位）
   vdh list | grep "ID:"
   
   # 使用完整的12位ID
   vdh task abcd1234efgh
   ```

### 调试技巧

```bash
# 查看完整系统状态
./status.sh

# 查看服务日志
./status.sh logs

# 测试 socket 连接
echo "STATUS" | nc -U /tmp/video_downloader.sock

# 数据库调试
sqlite3 ~/video_downloader.db "
SELECT id, url, status, created_at 
FROM tasks 
ORDER BY created_at DESC 
LIMIT 5;
"

# 清理所有资源
make clean
rm -f /tmp/video_downloader.sock
rm -f ~/video_downloader.db

# 性能监控
while true; do
    echo "=== $(date) ==="
    vdh stats
    echo "数据库大小: $(du -h ~/video_downloader.db 2>/dev/null || echo '未找到')"
    sleep 60
done
```

## 🚀 更新日志

### v2.0.0 (最新版本)
- ✅ **SQLite3 数据库支持** - 持久化任务数据
- ✅ **12位随机任务ID** - 唯一任务标识符
- ✅ **6种任务状态** - pending/queued/downloading/completed/failed/cancelled
- ✅ **断点恢复功能** - 服务器重启后自动恢复任务
- ✅ **任务查询命令** - `vdh task <id>` 查看详细信息
- ✅ **批量任务管理** - `vdh list`, `vdh stats`, `vdh cleanup`
- ✅ **数据库索引优化** - 提升查询性能
- ✅ **事务安全性** - 确保数据一致性

### v1.0.0
- ✅ 重命名为简洁的 `vdh` 命令
- ✅ 完整的 Homebrew 支持
- ✅ 智能下载队列管理
- ✅ Unix Domain Socket 通信
- ✅ 实时状态监控
- ✅ 优雅的服务管理

## 📊 数据库架构

VDH v2.0.0 使用 SQLite3 数据库存储任务信息:

```sql
-- 任务表结构
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,              -- 12位随机ID
    url TEXT NOT NULL,                -- 视频URL
    status TEXT NOT NULL,             -- 任务状态
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,              -- 开始下载时间
    completed_at DATETIME,            -- 完成时间
    error_message TEXT,               -- 错误信息
    file_path TEXT                    -- 下载文件路径
);

-- 性能优化索引
CREATE INDEX idx_status ON tasks(status);
CREATE INDEX idx_created_at ON tasks(created_at);
```

### 数据库位置
- **开发环境**: `~/video_downloader.db`
- **生产环境**: `~/Library/Application Support/VideoDownloaderHelper/video_downloader.db`

### 数据备份
```bash
# 备份数据库
cp ~/video_downloader.db ~/video_downloader_backup_$(date +%Y%m%d).db

# 查看数据库内容
sqlite3 ~/video_downloader.db "SELECT * FROM tasks ORDER BY created_at DESC LIMIT 10;"
```

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

---

**VDH - 让视频下载变得简单优雅** 🎬✨
