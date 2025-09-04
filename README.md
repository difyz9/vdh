# VDH (Video Downloader Helper) v2.0.0

🎬 一个专业的视频下载助手工具，配备 SQLite3 数据库、智能队列管理和 Unix Domain Socket 通信。

## ✨ 新版本亮点

- 🗃️ **SQLite3 数据库**：持久化任务存储，服务器重启不丢失数据
- 🏷️ **12位随机ID**：每个任务自动分配唯一的12位随机字符串标识符
- 📊 **任务状态跟踪**：6种状态精确管理任务生命周期
- 🔍 **任务查询系统**：通过ID快速查询任务详情和状态
- 🚀 **队列恢复**：服务器重启后自动恢复未完成任务
- 📈 **统计面板**：详细的任务统计和历史记录
- ⚙️ **配置管理**：YAML配置文件支持自定义yt-dlp路径、代理、输出目录等
- 🎛️ **服务管理**：简单的start/stop/status命令管理服务器

## 🎯 核心特性

- 🚀 **简洁命令**：只需输入 `vdh` 而不是冗长的 `video-downloader-helper`
- 🔧 **智能队列**：自动管理并发下载，避免系统资源过载
- 📡 **Unix Socket**：真正的 IPC 通信，比文件监控快 100 倍
- 🍺 **Homebrew 集成**：完整的服务管理支持
- 📊 **实时监控**：随时查看下载状态和队列情况
- 🗃️ **数据持久化**：SQLite3 数据库确保数据安全
- ⚙️ **灵活配置**：YAML配置文件支持自定义各种参数
- 🌐 **代理支持**：支持HTTP/SOCKS5代理配置
- 🎛️ **服务管理**：start/stop/status命令轻松管理服务器

## 🚀 快速开始

### 安装

#### 方式 1: 本地快速安装（推荐）
```bash
# 一键编译并安装到系统
./install-local.sh

# 或仅编译测试
./install-local.sh --build-only
```

#### 方式 2: 使用 Makefile
```bash
# 构建和安装
make install

# 检查状态
make service-status
```

#### 方式 3: 完整安装脚本
```bash
# 多种安装选项，包括 Homebrew 支持
./install.sh
```

#### 方式 4: Homebrew（开发模式）
```bash
make homebrew-tap
brew install local/vdh/vdh
```

### 🔧 安装说明

#### install-local.sh 特性
- ✅ **自动检查依赖**：检查Swift编译器和源文件
- 🔨 **优化编译**：使用 `-O` 参数进行性能优化
- 📁 **目录管理**：自动创建 `~/.vdh` 配置目录
- 🔐 **权限处理**：智能处理系统目录写入权限
- 🔄 **版本备份**：安装前自动备份现有版本
- ✅ **安装测试**：安装后自动验证功能

#### 安装脚本选项
```bash
./install-local.sh          # 完整安装流程
./install-local.sh --build-only    # 仅编译，不安装
./install-local.sh --force         # 强制重新安装
./install-local.sh --help          # 显示帮助
```

#### 系统要求
- **操作系统**：macOS 10.15+ 
- **编译器**：Swift 5.0+ (Xcode 或 Swift Toolchain)
- **权限**：安装到 `/usr/local/bin` 需要管理员权限

#### 安装路径
- **可执行文件**：`/usr/local/bin/vdh`
- **配置目录**：`~/.vdh/`
- **配置文件**：`~/.vdh/config.yaml`
- **数据库**：`~/.vdh/vdh.db`
- **日志文件**：`~/.vdh/vdh.log`

### 基本使用

```bash
# 🚀 启动服务器（后台运行）
vdh start

# 📥 发送下载请求 (返回12位任务ID)
vdh -i "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
# 输出: OK: Task added with ID abc123def456

# 📊 查看服务器和队列状态
vdh status

# 🔍 查询特定任务状态
vdh task abc123def456

# 📋 查看最近任务列表
vdh list

# � 查看详细统计
vdh stats

# 🛑 停止服务器
vdh stop

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
| `start` | 在后台启动VDH服务器 | `vdh start` |
| `stop` | 停止运行中的VDH服务器 | `vdh stop` |
| `status` | 检查服务器和队列状态 | `vdh status` |
| `config` | 管理配置文件 | `vdh config show` |
| `server` | 启动Unix socket服务器(前台) | `vdh server` |
| `input`, `-i` | 发送下载请求到服务器 | `vdh -i "URL"` |
| `task` | 查询指定任务详情 | `vdh task abc123def456` |
| `list`, `ls` | 列出最近的任务 | `vdh list` |
| `stats` | 显示任务统计信息 | `vdh stats` |
| `cleanup` | 清理旧的已完成任务 | `vdh cleanup` |
| `download`, `-d` | 直接下载(跳过队列) | `vdh -d "URL"` |
| `test` | 测试socket通信 | `vdh test` |
| `help`, `--help`, `-h` | 显示帮助信息 | `vdh --help` |
| `version`, `--version`, `-v` | 显示版本信息 | `vdh --version` |

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

- **路径**: `~/.vdh/video_downloader.db`
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

## ⚙️ 配置管理

VDH v2.0.0 支持通过 YAML 配置文件自定义各种参数。

### 配置文件位置

- **文件路径**: `~/.vdh/config.yaml`
- **格式**: YAML (Yet Another Markup Language)
- **创建**: 首次运行时自动创建

### 配置选项

```yaml
# yt-dlp 可执行文件路径
yt_dlp_path: "/opt/homebrew/bin/yt-dlp"

# 视频下载输出目录
output_directory: "~/Downloads/VideoDownloader"

# 代理设置 (可选)
proxy_url: "http://127.0.0.1:7890"  # HTTP代理
# proxy_url: "socks5://127.0.0.1:1080"  # SOCKS5代理

# 最大并发下载数
max_concurrent_downloads: 2

# 任务清理保留天数
cleanup_days: 30

# 启用详细日志
enable_logging: true

# 临时文件目录
temp_directory: "~/.vdh/temp"
```

### 配置管理命令

| 命令 | 功能 | 示例 |
|------|------|------|
| `vdh config` | 显示当前配置 | `vdh config` |
| `vdh config show` | 显示当前配置 | `vdh config show` |
| `vdh config edit` | 打开配置文件编辑 | `vdh config edit` |
| `vdh config reload` | 重新加载配置 | `vdh config reload` |
| `vdh config reset` | 重置为默认配置 | `vdh config reset` |

### 配置示例

```bash
# 查看当前配置
vdh config show

# 编辑配置文件
vdh config edit

# 手动编辑后重新加载
vdh config reload

# 重置所有设置
vdh config reset
```

### 常用配置场景

#### 1. 配置代理服务器
```yaml
# HTTP 代理
proxy_url: "http://127.0.0.1:7890"

# SOCKS5 代理
proxy_url: "socks5://127.0.0.1:1080"

# 企业代理
proxy_url: "http://proxy.company.com:8080"
```

#### 2. 自定义输出目录
```yaml
# 默认位置
output_directory: "~/Downloads/VideoDownloader"

# 外部硬盘
output_directory: "/Volumes/ExternalDrive/Videos"

# 自定义路径
output_directory: "~/Movies/Downloaded"
```

#### 3. 性能调优
```yaml
# 高性能设置 (多核CPU)
max_concurrent_downloads: 4

# 保守设置 (低配置设备)
max_concurrent_downloads: 1

# 快速清理 (节省空间)
cleanup_days: 7
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
vdh start

# 添加下载任务
vdh -i "https://youtube.com/watch?v=abc123"
# 输出: OK: Task added with ID def456ghi789

# 查询任务状态
vdh task def456ghi789

# 查看服务器状态
vdh status

# 查看所有任务
vdh list

# 停止服务
vdh stop

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
└── README.md               # 本文档

~/.vdh/
├── config.yaml             # 配置文件 (YAML格式)
├── video_downloader.db     # SQLite3 数据库文件
└── temp/                   # 临时文件目录
```

### 核心组件

- **ConfigManager**: 配置文件管理类
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
   ls -la ~/.vdh/video_downloader.db
   
   # 修复数据库
   sqlite3 ~/.vdh/video_downloader.db "PRAGMA integrity_check;"
   
   # 重置数据库（注意：会丢失所有数据）
   rm ~/.vdh/video_downloader.db
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
sqlite3 ~/.vdh/video_downloader.db "
SELECT id, url, status, created_at 
FROM tasks 
ORDER BY created_at DESC 
LIMIT 5;
"

# 清理所有资源
make clean
rm -f /tmp/video_downloader.sock
rm -f ~/.vdh/video_downloader.db

# 性能监控
while true; do
    echo "=== $(date) ==="
    vdh stats
    echo "数据库大小: $(du -h ~/.vdh/video_downloader.db 2>/dev/null || echo '未找到')"
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
- **默认位置**: `~/.vdh/video_downloader.db`
- **配置文件夹**: `~/.vdh/` (自动创建)

### 数据备份
```bash
# 备份数据库
cp ~/.vdh/video_downloader.db ~/.vdh/video_downloader_backup_$(date +%Y%m%d).db

# 查看数据库内容
sqlite3 ~/.vdh/video_downloader.db "SELECT * FROM tasks ORDER BY created_at DESC LIMIT 10;"

# 检查.vdh文件夹
ls -la ~/.vdh/
```

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

---

**VDH - 让视频下载变得简单优雅** 🎬✨
