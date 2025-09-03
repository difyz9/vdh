// VideoDownloaderHelper - Helper Tool for macOS Sandbox Bypass
import Foundation
import Darwin
import SQLite3

// 任务状态枚举
enum TaskStatus: String, CaseIterable {
    case pending = "pending"
    case queued = "queued"
    case downloading = "downloading"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

// 任务结构体
struct DownloadTask {
    let id: String  // 改为String类型的12位随机数
    let url: String
    let status: TaskStatus
    let createdAt: Date
    let startedAt: Date?
    let completedAt: Date?
    let errorMessage: String?
    let filePath: String?
}

// SQLite数据库管理类
class DatabaseManager {
    private var db: OpaquePointer?
    private let dbPath: String
    private let dbQueue = DispatchQueue(label: "database.queue", qos: .utility)
    
    init() {
        // 数据库文件路径 - 存储在用户根目录的.vdh文件夹下
        let vdhPath = NSHomeDirectory() + "/.vdh"
        try? FileManager.default.createDirectory(atPath: vdhPath, withIntermediateDirectories: true)
        self.dbPath = vdhPath + "/video_downloader.db"
        
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
        // 生成12位随机数ID
    private func generateTaskId() -> String {
        let digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<12).map { _ in digits.randomElement()! })
    }
    
    private func openDatabase() {
        let result = sqlite3_open(dbPath, &db)
        if result != SQLITE_OK {
            print("❌ Unable to open database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        print("✅ Database opened successfully at: \(dbPath)")
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("❌ Error closing database")
        }
        db = nil
    }
    
    private func createTables() {
        let createTasksTableSQL = """
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                started_at DATETIME,
                completed_at DATETIME,
                error_message TEXT,
                file_path TEXT
            );
        """
        
        if sqlite3_exec(db, createTasksTableSQL, nil, nil, nil) == SQLITE_OK {
            print("✅ Tasks table created successfully")
        } else {
            print("❌ Failed to create tasks table: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        // 创建索引以提高查询性能
        let createIndexSQL = """
            CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
            CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);
        """
        
        if sqlite3_exec(db, createIndexSQL, nil, nil, nil) == SQLITE_OK {
            print("✅ Database indexes created successfully")
        } else {
            print("❌ Failed to create indexes: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    // 添加新任务
    func addTask(url: String) -> String? {
        return dbQueue.sync {
            let taskId = generateTaskId()
            let insertSQL = "INSERT INTO tasks (id, url, status) VALUES (?, ?, ?)"
            var statement: OpaquePointer?
            
            defer {
                sqlite3_finalize(statement)
            }
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
                let taskIdCString = taskId.cString(using: .utf8)!
                let urlCString = url.cString(using: .utf8)!
                let statusCString = TaskStatus.pending.rawValue.cString(using: .utf8)!
                
                sqlite3_bind_text(statement, 1, taskIdCString, -1, nil)
                sqlite3_bind_text(statement, 2, urlCString, -1, nil)
                sqlite3_bind_text(statement, 3, statusCString, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("✅ Task added to database with ID: \(taskId), URL: \(url), Status: pending")
                    return taskId
                } else {
                    print("❌ Failed to insert task: \(String(cString: sqlite3_errmsg(db)))")
                }
            } else {
                print("❌ Failed to prepare insert statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            return nil
        }
    }
    
    // 更新任务状态
    func updateTaskStatus(id: String, status: TaskStatus, errorMessage: String? = nil, filePath: String? = nil) -> Bool {
        return dbQueue.sync {
            var updateSQL = "UPDATE tasks SET status = ?"
            var paramCount = 1
            
            switch status {
            case .downloading:
                updateSQL += ", started_at = CURRENT_TIMESTAMP"
            case .completed, .failed, .cancelled:
                updateSQL += ", completed_at = CURRENT_TIMESTAMP"
            default:
                break
            }
            
            if errorMessage != nil {
                updateSQL += ", error_message = ?"
                paramCount += 1
            }
            
            if filePath != nil {
                updateSQL += ", file_path = ?"
                paramCount += 1
            }
            
            updateSQL += " WHERE id = ?"
            paramCount += 1
            
            var statement: OpaquePointer?
            
            defer {
                sqlite3_finalize(statement)
            }
            
            if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
                var bindIndex: Int32 = 1
                
                let statusCString = status.rawValue.cString(using: .utf8)!
                sqlite3_bind_text(statement, bindIndex, statusCString, -1, nil)
                bindIndex += 1
                
                if let error = errorMessage {
                    let errorCString = error.cString(using: .utf8)!
                    sqlite3_bind_text(statement, bindIndex, errorCString, -1, nil)
                    bindIndex += 1
                }
                
                if let path = filePath {
                    let pathCString = path.cString(using: .utf8)!
                    sqlite3_bind_text(statement, bindIndex, pathCString, -1, nil)
                    bindIndex += 1
                }
                
                let idCString = id.cString(using: .utf8)!
                sqlite3_bind_text(statement, bindIndex, idCString, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("✅ Task \(id) status updated to: \(status.rawValue)")
                    return true
                } else {
                    print("❌ Failed to update task status: \(String(cString: sqlite3_errmsg(db)))")
                }
            } else {
                print("❌ Failed to prepare update statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            return false
        }
    }
    
    // 获取任务详情
    func getTask(id: String) -> DownloadTask? {
        return dbQueue.sync {
            let selectSQL = """
                SELECT id, url, status, created_at, started_at, completed_at, error_message, file_path
                FROM tasks WHERE id = ?
            """
            var statement: OpaquePointer?
            
            defer {
                sqlite3_finalize(statement)
            }
            
            if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
                let idCString = id.cString(using: .utf8)!
                sqlite3_bind_text(statement, 1, idCString, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    return parseTaskFromStatement(statement)
                } else {
                    print("❌ No task found with ID: \(id)")
                }
            } else {
                print("❌ Failed to prepare select statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            return nil
        }
    }
    
    // 获取所有任务列表
    func getAllTasks(status: TaskStatus? = nil, limit: Int = 100) -> [DownloadTask] {
        return dbQueue.sync {
            var selectSQL = """
                SELECT id, url, status, created_at, started_at, completed_at, error_message, file_path
                FROM tasks
            """
            
            if status != nil {
                selectSQL += " WHERE status = ?"
            }
            
            selectSQL += " ORDER BY created_at DESC LIMIT ?"
            
            var statement: OpaquePointer?
            var tasks: [DownloadTask] = []
            
            defer {
                sqlite3_finalize(statement)
            }
            
            if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
                var bindIndex: Int32 = 1
                
                if let statusFilter = status {
                    sqlite3_bind_text(statement, bindIndex, statusFilter.rawValue, -1, nil)
                    bindIndex += 1
                }
                
                sqlite3_bind_int(statement, bindIndex, Int32(limit))
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let task = parseTaskFromStatement(statement) {
                        tasks.append(task)
                    }
                }
            } else {
                print("❌ Failed to prepare select all statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            return tasks
        }
    }
    
    // 获取任务统计信息
    func getTaskStats() -> [TaskStatus: Int] {
        return dbQueue.sync {
            let selectSQL = "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
            var statement: OpaquePointer?
            var stats: [TaskStatus: Int] = [:]
            
            defer {
                sqlite3_finalize(statement)
            }
            
            if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let statusStr = sqlite3_column_text(statement, 0),
                       let status = TaskStatus(rawValue: String(cString: statusStr)) {
                        let count = Int(sqlite3_column_int(statement, 1))
                        stats[status] = count
                    }
                }
            } else {
                print("❌ Failed to prepare stats statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            return stats
        }
    }
    
    // 清理旧任务（可选，删除超过指定天数的已完成任务）
    func cleanupOldTasks(olderThanDays days: Int = 30) -> Int {
        return dbQueue.sync {
            let deleteSQL = """
                DELETE FROM tasks 
                WHERE (status = 'completed' OR status = 'failed') 
                AND created_at < datetime('now', '-\(days) days')
            """
            
            if sqlite3_exec(db, deleteSQL, nil, nil, nil) == SQLITE_OK {
                let deletedCount = Int(sqlite3_changes(db))
                print("✅ Cleaned up \(deletedCount) old tasks")
                return deletedCount
            } else {
                print("❌ Failed to cleanup old tasks: \(String(cString: sqlite3_errmsg(db)))")
                return 0
            }
        }
    }
    
    private func parseTaskFromStatement(_ statement: OpaquePointer?) -> DownloadTask? {
        guard let statement = statement else { return nil }
        
        guard let idCStr = sqlite3_column_text(statement, 0) else { return nil }
        let id = String(cString: idCStr)
        
        guard let urlCStr = sqlite3_column_text(statement, 1) else { return nil }
        let url = String(cString: urlCStr)
        
        guard let statusCStr = sqlite3_column_text(statement, 2),
              let status = TaskStatus(rawValue: String(cString: statusCStr)) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 创建时间
        var createdAt = Date()
        if let createdCStr = sqlite3_column_text(statement, 3) {
            createdAt = dateFormatter.date(from: String(cString: createdCStr)) ?? Date()
        }
        
        // 开始时间
        var startedAt: Date?
        if let startedCStr = sqlite3_column_text(statement, 4) {
            startedAt = dateFormatter.date(from: String(cString: startedCStr))
        }
        
        // 完成时间
        var completedAt: Date?
        if let completedCStr = sqlite3_column_text(statement, 5) {
            completedAt = dateFormatter.date(from: String(cString: completedCStr))
        }
        
        // 错误信息
        var errorMessage: String?
        if let errorCStr = sqlite3_column_text(statement, 6) {
            errorMessage = String(cString: errorCStr)
        }
        
        // 文件路径
        var filePath: String?
        if let pathCStr = sqlite3_column_text(statement, 7) {
            filePath = String(cString: pathCStr)
        }
        
        return DownloadTask(
            id: id,
            url: url,
            status: status,
            createdAt: createdAt,
            startedAt: startedAt,
            completedAt: completedAt,
            errorMessage: errorMessage,
            filePath: filePath
        )
    }
}

class VideoDownloaderHelper {
    private let socketPath = "/tmp/video_downloader.sock"
    private var serverSocket: Int32 = -1
    private var isServerRunning = true
    
    // 数据库管理器
    let dbManager = DatabaseManager()
    
    // 下载队列管理
    private let downloadQueue = DispatchQueue(label: "downloadQueue", qos: .background)
    private let semaphore: DispatchSemaphore
    private var activeDownloads: [String: String] = [:]  // taskId: url
    private var queuedDownloads: [String] = []  // 只存储任务ID (String类型)
    private let maxConcurrentDownloads: Int
    private let queueLock = NSLock()
    
    init(maxConcurrentDownloads: Int = 2) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.semaphore = DispatchSemaphore(value: maxConcurrentDownloads)
        
        // 启动时恢复未完成的任务
        recoverPendingTasks()
    }
    // 恢复未完成的任务
    private func recoverPendingTasks() {
        // 将正在下载的任务重置为待处理状态
        let downloadingTasks = dbManager.getAllTasks(status: .downloading)
        for task in downloadingTasks {
            _ = dbManager.updateTaskStatus(id: task.id, status: .pending)
        }
        
        // 获取所有待处理的任务 (pending状态的任务需要移到队列中)
        let pendingTasks = dbManager.getAllTasks(status: .pending)
        let queuedTasks = dbManager.getAllTasks(status: .queued)
        
        queueLock.lock()
        // 将pending任务更新为queued状态并加入队列
        for task in pendingTasks {
            _ = dbManager.updateTaskStatus(id: task.id, status: .queued)
            queuedDownloads.append(task.id)
        }
        // 加入已经排队的任务
        queuedDownloads.append(contentsOf: queuedTasks.map { $0.id })
        queueLock.unlock()
        
        let totalRecovered = pendingTasks.count + queuedTasks.count
        if totalRecovered > 0 {
            print("📋 Recovered \(totalRecovered) pending tasks from database")
            processDownloadQueue()
        }
    }
    
    func startServer() {
        print("Video Downloader Helper started")
        print("Creating Unix socket at: \(socketPath)")
        
        // 创建 Unix Domain Socket
        serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverSocket != -1 else {
            print("Failed to create socket: \(String(cString: strerror(errno)))")
            return
        }
        
        // 删除可能存在的旧 socket 文件
        unlink(socketPath)
        
        // 设置 socket 地址
        var serverAddr = sockaddr_un()
        serverAddr.sun_family = sa_family_t(AF_UNIX)
        
        let pathBytes = socketPath.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: serverAddr.sun_path) else {
            print("Socket path too long")
            close(serverSocket)
            return
        }
        
        withUnsafeMutablePointer(to: &serverAddr.sun_path) { pathPtr in
            pathPtr.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { charPtr in
                _ = pathBytes.withUnsafeBufferPointer { buffer in
                    memcpy(charPtr, buffer.baseAddress, buffer.count)
                }
            }
        }
        
        // 绑定 socket
        let bindResult = withUnsafePointer(to: &serverAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        guard bindResult == 0 else {
            print("Failed to bind socket: \(String(cString: strerror(errno)))")
            close(serverSocket)
            return
        }
        
        // 监听连接
        guard listen(serverSocket, 5) == 0 else {
            print("Failed to listen on socket: \(String(cString: strerror(errno)))")
            close(serverSocket)
            return
        }
        
        print("Socket server listening on \(socketPath)")
        
        // 接受连接循环
        while isServerRunning {
            let clientSocket = accept(serverSocket, nil, nil)
            guard clientSocket != -1 else {
                if isServerRunning {  // 只在仍在运行时打印错误
                    print("Failed to accept connection: \(String(cString: strerror(errno)))")
                }
                continue
            }
            
            if !isServerRunning {
                close(clientSocket)
                break
            }
            
            print("Client connected")
            handleClient(clientSocket: clientSocket)
            close(clientSocket)
        }
        
        // 清理资源
        close(serverSocket)
        unlink(socketPath)
        print("✅ Server stopped and resources cleaned up")
    }
    
    func stopServer() {
        print("Stopping server...")
        isServerRunning = false
        
        // 关闭服务器socket以中断accept循环
        if serverSocket != -1 {
            close(serverSocket)
            unlink(socketPath)
        }
        
        // 退出程序
        exit(0)
    }
    
    private func handleClient(clientSocket: Int32) {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        let bytesRead = recv(clientSocket, &buffer, bufferSize - 1, 0)
        guard bytesRead > 0 else {
            print("Failed to read from client socket")
            return
        }
        
        buffer[bytesRead] = 0 // 确保字符串结束
        guard let receivedData = String(bytes: buffer[0..<bytesRead], encoding: .utf8) else {
            print("Failed to decode received data")
            return
        }
        
        let command = receivedData.trimmingCharacters(in: .whitespacesAndNewlines)
        if !command.isEmpty {
            var response = ""
            
            if command == "STATUS" {
                // 处理队列状态查询请求
                let status = getQueueStatus()
                let stats = dbManager.getTaskStats()
                response = "QUEUE: \(status.active) active, \(status.queued) queued | TOTAL: \(stats.values.reduce(0, +)) tasks"
                for (status, count) in stats {
                    response += " | \(status.rawValue.uppercased()): \(count)"
                }
                response += "\n"
                print("📊 Status requested - \(response.trimmingCharacters(in: .whitespacesAndNewlines))")
            } else if command.hasPrefix("TASK:") {
                // 处理任务详情查询请求 格式: TASK:123456789012
                let taskIdStr = String(command.dropFirst(5))
                if let task = dbManager.getTask(id: taskIdStr) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    response = "TASK \(task.id): \(task.status.rawValue.uppercased())\n"
                    response += "URL: \(task.url)\n"
                    response += "Created: \(formatter.string(from: task.createdAt))\n"
                    
                    if let startedAt = task.startedAt {
                        response += "Started: \(formatter.string(from: startedAt))\n"
                    }
                    
                    if let completedAt = task.completedAt {
                        response += "Completed: \(formatter.string(from: completedAt))\n"
                    }
                    
                    if let filePath = task.filePath {
                        response += "File: \(filePath)\n"
                    }
                    
                    if let errorMessage = task.errorMessage {
                        response += "Error: \(errorMessage)\n"
                    }
                } else {
                    response = "ERROR: Task not found\n"
                }
                print("� Task \(taskIdStr) details requested")
            } else if command == "LIST" {
                // 处理任务列表查询请求
                let recentTasks = dbManager.getAllTasks(limit: 10)
                response = "RECENT TASKS (\(recentTasks.count)):\n"
                for task in recentTasks {
                    let statusEmoji = getStatusEmoji(task.status)
                    response += "\(statusEmoji) ID:\(task.id) [\(task.status.rawValue.uppercased())] \(task.url)\n"
                }
                print("📋 Task list requested")
            } else if command == "SHUTDOWN" {
                // 处理关闭服务器请求
                response = "OK: Server shutting down\n"
                print("🛑 Shutdown command received, stopping server...")
                
                // 发送响应
                _ = send(clientSocket, response, response.count, 0)
                
                // 优雅关闭服务器
                DispatchQueue.main.async {
                    self.stopServer()
                }
                return
            } else {
                // 处理下载请求
                if let taskId = addToDownloadQueue(url: command) {
                    print("Received download request for: \(command) (ID: \(taskId))")
                    response = "OK: Task added with ID \(taskId)\n"
                } else {
                    response = "ERROR: Failed to add task\n"
                }
            }
            
            // 发送响应
            _ = send(clientSocket, response, response.count, 0)
        }
    }
    
    func getStatusEmoji(_ status: TaskStatus) -> String {
        switch status {
        case .pending: return "⏸️"
        case .queued: return "⏳"
        case .downloading: return "⬇️"
        case .completed: return "✅"
        case .failed: return "❌"
        case .cancelled: return "🚫"
        }
    }
    
    private func addToDownloadQueue(url: String) -> String? {
        // 首先在数据库中创建任务
        guard let taskId = dbManager.addTask(url: url) else {
            print("❌ Failed to add task to database")
            return nil
        }
        
        queueLock.lock()
        defer { queueLock.unlock() }
        
        // 将任务状态从pending更新为queued
        _ = dbManager.updateTaskStatus(id: taskId, status: .queued)
        queuedDownloads.append(taskId)
        
        print("📥 Added to queue: \(url) (ID: \(taskId))")
        print("📊 Queue status: \(activeDownloads.count) active, \(queuedDownloads.count) queued")
        
        // 尝试启动下载
        processDownloadQueue()
        
        return taskId
    }
    
    private func processDownloadQueue() {
        downloadQueue.async {
            while true {
                self.queueLock.lock()
                
                // 检查是否有可用的下载槽位和队列中的任务
                guard self.activeDownloads.count < self.maxConcurrentDownloads && !self.queuedDownloads.isEmpty else {
                    self.queueLock.unlock()
                    break
                }
                
                // 取出队列中的第一个任务ID
                let taskId = self.queuedDownloads.removeFirst()
                
                // 从数据库获取任务详情
                guard let task = self.dbManager.getTask(id: taskId) else {
                    print("❌ Task \(taskId) not found in database")
                    self.queueLock.unlock()
                    continue
                }
                
                self.activeDownloads[taskId] = task.url
                
                print("🚀 Starting download: \(task.url) (ID: \(taskId))")
                print("📊 Queue status: \(self.activeDownloads.count) active, \(self.queuedDownloads.count) queued")
                
                self.queueLock.unlock()
                
                // 更新任务状态为正在下载
                _ = self.dbManager.updateTaskStatus(id: taskId, status: .downloading)
                
                // 在后台执行下载
                DispatchQueue.global(qos: .background).async {
                    let success = self.downloadVideo(url: task.url, downloadId: taskId)
                    
                    // 下载完成后（无论成功或失败），更新状态并减少活跃下载数
                    self.queueLock.lock()
                    self.activeDownloads.removeValue(forKey: taskId)
                    let statusEmoji = success ? "✅" : "❌"
                    let statusText = success ? "completed successfully" : "failed"
                    print("\(statusEmoji) Download \(statusText): \(task.url) (ID: \(taskId))")
                    print("📊 Queue status: \(self.activeDownloads.count) active, \(self.queuedDownloads.count) queued")
                    self.queueLock.unlock()
                    
                    // 更新数据库中的任务状态
                    let finalStatus: TaskStatus = success ? .completed : .failed
                    _ = self.dbManager.updateTaskStatus(id: taskId, status: finalStatus)
                    
                    // 递归处理队列中的下一个任务
                    self.processDownloadQueue()
                }
            }
        }
    }
    
    func getQueueStatus() -> (active: Int, queued: Int) {
        queueLock.lock()
        defer { queueLock.unlock() }
        return (active: activeDownloads.count, queued: queuedDownloads.count)
    }
    
    deinit {
        if serverSocket != -1 {
            close(serverSocket)
            unlink(socketPath)
        }
    }
    
    func downloadVideo(url: String, downloadId: String = "") -> Bool {
        let prefix = !downloadId.isEmpty ? "[ID:\(downloadId)]" : ""
        print("\(prefix) 🎬 Starting download for: \(url)")
        
        // 第一步：验证URL格式
        guard isValidURL(url) else {
            let errorMsg = "Invalid URL format"
            print("\(prefix) ❌ Error: \(errorMsg)")
            print("\(prefix) 💡 Please check the URL and try again")
            
            if !downloadId.isEmpty {
                _ = dbManager.updateTaskStatus(id: downloadId, status: .failed, errorMessage: errorMsg)
            }
            return false
        }
        
        // 检查 yt-dlp 是否安装
        let ytDlpPaths = [
            "/Users/apple/opt/yt-dlp/yt-dlp",  // 用户自定义路径 (优先)
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        
        var ytDlpPath: String?
        for path in ytDlpPaths {
            if FileManager.default.fileExists(atPath: path) {
                ytDlpPath = path
                break
            }
        }
        
        guard let validPath = ytDlpPath else {
            let errorMsg = "yt-dlp not found in standard paths"
            print("\(prefix) ❌ Error: \(errorMsg). Searched paths:")
            for path in ytDlpPaths {
                print("  - \(path)")
            }
            print("\(prefix) 💡 Install yt-dlp with: brew install yt-dlp")
            
            if !downloadId.isEmpty {
                _ = dbManager.updateTaskStatus(id: downloadId, status: .failed, errorMessage: errorMsg)
            }
            return false
        }
        
        print("\(prefix) 🛠️ Using yt-dlp at: \(validPath)")
        
        let task = Process()
        task.launchPath = validPath
        
        // 创建下载目录
        let downloadsPath = NSHomeDirectory() + "/Downloads/VideoDownloader"
        try? FileManager.default.createDirectory(atPath: downloadsPath, withIntermediateDirectories: true)
        
        // 生成输出文件名模板
        let outputTemplate = "\(downloadsPath)/%(title)s.%(id)s.%(ext)s"
        
        task.arguments = [
            "--proxy", "http://127.0.0.1:7890",
            "--cookies-from-browser", "chrome", 
            "--merge-output-format", "mp4",
            "--verbose",
            "--no-playlist",
            "--print", "filename",  // 打印实际文件名
            url,
            "-o", outputTemplate
        ]
        
        print("\(prefix) 📝 Download command: \(validPath) \(task.arguments!.joined(separator: " "))")
        print("\(prefix) 📁 Download directory: \(downloadsPath)")
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        var actualFilePath: String?
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("\(prefix) 📄 yt-dlp output:")
                print(output)
                
                // 尝试从输出中提取实际文件路径
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains(downloadsPath) && (line.hasSuffix(".mp4") || line.hasSuffix(".mkv") || line.hasSuffix(".webm")) {
                        actualFilePath = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
            }
            
            if task.terminationStatus == 0 {
                print("\(prefix) ✅ Download completed successfully!")
                
                if !downloadId.isEmpty {
                    _ = dbManager.updateTaskStatus(id: downloadId, status: .completed, filePath: actualFilePath)
                }
                return true
            } else {
                let errorMsg = "Download failed with exit code: \(task.terminationStatus)"
                print("\(prefix) ❌ \(errorMsg)")
                
                if !downloadId.isEmpty {
                    _ = dbManager.updateTaskStatus(id: downloadId, status: .failed, errorMessage: errorMsg)
                }
                return false
            }
            
        } catch {
            let errorMsg = "Failed to execute yt-dlp: \(error)"
            print("\(prefix) ❌ \(errorMsg)")
            
            if !downloadId.isEmpty {
                _ = dbManager.updateTaskStatus(id: downloadId, status: .failed, errorMessage: errorMsg)
            }
            return false
        }
    }
    
    // URL格式验证
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased() else {
            return false
        }
        return ["http", "https"].contains(scheme)
    }
}

// 信号处理用于优雅关闭
var globalHelper: VideoDownloaderHelper?

func signalHandler(signal: Int32) {
    print("\nReceived signal \(signal), shutting down gracefully...")
    exit(0)
}

// Unix Socket 客户端测试函数
func sendToSocket(url: String) -> Bool {
    return sendToSocketGeneric(message: url)
}

// 查询任务详情
func sendTaskQuery(taskId: String) -> Bool {
    return sendToSocketGeneric(message: "TASK:\(taskId)")
}

// 查询任务列表
func sendListQuery() -> Bool {
    return sendToSocketGeneric(message: "LIST")
}

// 查询服务器状态
func sendStatusRequest() -> Bool {
    return sendToSocketGeneric(message: "STATUS")
}

// 通用 socket 通信函数
func sendToSocketGeneric(message: String) -> Bool {
    let socketPath = "/tmp/video_downloader.sock"
    
    // 创建客户端 socket
    let clientSocket = socket(AF_UNIX, SOCK_STREAM, 0)
    guard clientSocket != -1 else {
        print("Failed to create client socket: \(String(cString: strerror(errno)))")
        return false
    }
    
    defer { close(clientSocket) }
    
    // 设置服务器地址
    var serverAddr = sockaddr_un()
    serverAddr.sun_family = sa_family_t(AF_UNIX)
    
    let pathBytes = socketPath.utf8CString
    withUnsafeMutablePointer(to: &serverAddr.sun_path) { pathPtr in
        pathPtr.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { charPtr in
            _ = pathBytes.withUnsafeBufferPointer { buffer in
                memcpy(charPtr, buffer.baseAddress, buffer.count)
            }
        }
    }
    
    // 连接到服务器
    let connectResult = withUnsafePointer(to: &serverAddr) { ptr in
        ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
            connect(clientSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
    
    guard connectResult == 0 else {
        print("Failed to connect to socket server: \(String(cString: strerror(errno)))")
        print("Make sure the helper tool server is running with: vdh server")
        return false
    }
    
    // 发送消息
    let bytesToSend = message.count
    let bytesSent = send(clientSocket, message, bytesToSend, 0)
    
    guard bytesSent == bytesToSend else {
        print("Failed to send complete data to server")
        return false
    }
    
    // 读取服务器响应
    var buffer = [UInt8](repeating: 0, count: 2048)  // 增加缓冲区大小
    let bytesReceived = recv(clientSocket, &buffer, 2047, 0)
    
    if bytesReceived > 0 {
        buffer[bytesReceived] = 0
        if let response = String(bytes: buffer[0..<bytesReceived], encoding: .utf8) {
            print(response.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    return true
}

// 服务器管理函数
func isServerRunning() -> Bool {
    // 尝试连接到socket来检查服务器是否运行
    let socketPath = "/tmp/video_downloader.sock"
    let clientSocket = socket(AF_UNIX, SOCK_STREAM, 0)
    
    guard clientSocket != -1 else {
        return false
    }
    
    defer {
        close(clientSocket)
    }
    
    var serverAddr = sockaddr_un()
    serverAddr.sun_family = sa_family_t(AF_UNIX)
    
    let pathBytes = socketPath.utf8CString
    guard pathBytes.count <= MemoryLayout.size(ofValue: serverAddr.sun_path) else {
        return false
    }
    
    withUnsafeMutableBytes(of: &serverAddr.sun_path) { ptr in
        pathBytes.withUnsafeBufferPointer { pathPtr in
            ptr.copyMemory(from: UnsafeRawBufferPointer(pathPtr))
        }
    }
    
    let result = withUnsafePointer(to: serverAddr) { addrPtr in
        addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
            connect(clientSocket, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
    
    return result == 0
}

func startServerInBackground() {
    let executablePath = CommandLine.arguments[0]
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: executablePath)
    task.arguments = ["server"]
    
    // 重定向输出到 /dev/null 以在后台运行
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    task.standardInput = FileHandle.nullDevice
    
    do {
        try task.run()
        // 等待一小段时间确保服务器启动
        usleep(500000) // 0.5秒
        
        if isServerRunning() {
            print("✅ VDH server started successfully in background")
            print("📡 Socket: /tmp/video_downloader.sock")
            print("🗃️ Database: ~/.vdh/video_downloader.db")
        } else {
            print("❌ Failed to start VDH server")
            exit(1)
        }
    } catch {
        print("❌ Failed to start server: \(error)")
        exit(1)
    }
}

func stopServer() {
    // 发送停止信号到服务器
    if sendToSocket(url: "SHUTDOWN") {
        // 等待服务器关闭
        usleep(500000) // 0.5秒
        
        if !isServerRunning() {
            print("✅ VDH server stopped successfully")
        } else {
            print("⚠️ Server may still be running, trying force stop...")
            // 尝试通过进程名终止
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            task.arguments = ["-f", "vdh server"]
            
            do {
                try task.run()
                task.waitUntilExit()
                
                usleep(300000) // 0.3秒
                if !isServerRunning() {
                    print("✅ VDH server force stopped")
                } else {
                    print("❌ Failed to stop VDH server")
                }
            } catch {
                print("❌ Failed to force stop server: \(error)")
            }
        }
    } else {
        print("❌ Could not communicate with server to stop it")
        // 直接尝试终止进程
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        task.arguments = ["-f", "vdh server"]
        
        do {
            try task.run()
            task.waitUntilExit()
            print("✅ VDH server process terminated")
        } catch {
            print("❌ Failed to terminate server process: \(error)")
        }
    }
}

func checkServerStatus() {
    if isServerRunning() {
        print("✅ VDH server is running")
        print("📡 Socket: /tmp/video_downloader.sock")
        print("🗃️ Database: ~/.vdh/video_downloader.db")
        
        // 获取队列状态
        print("\n📊 Queue Status:")
        if sendStatusRequest() {
            // Status已经在sendStatusRequest中打印了
        } else {
            print("❌ Could not retrieve queue status")
        }
        
        // 获取统计信息
        print("\n📈 Statistics:")
        let helper = VideoDownloaderHelper()
        let stats = helper.dbManager.getTaskStats()
        for status in TaskStatus.allCases {
            let count = stats[status] ?? 0
            let emoji = helper.getStatusEmoji(status)
            print("  \(emoji) \(status.rawValue.capitalized): \(count)")
        }
        let total = stats.values.reduce(0, +)
        print("  📋 Total: \(total)")
        
    } else {
        print("❌ VDH server is not running")
        print("💡 Start with: vdh start")
    }
}


// 命令行参数处理
func main() {
    // 设置信号处理
    signal(SIGINT, signalHandler)
    signal(SIGTERM, signalHandler)
    
    let helper = VideoDownloaderHelper()
    globalHelper = helper
    
    if CommandLine.arguments.count > 1 {
        let command = CommandLine.arguments[1]
        
        switch command {
        case "start":
            print("🚀 Starting VDH server in background...")
            if isServerRunning() {
                print("⚠️ Server is already running")
                exit(0)
            }
            startServerInBackground()
            
        case "stop":
            print("🛑 Stopping VDH server...")
            if !isServerRunning() {
                print("⚠️ Server is not running")
                exit(0)
            }
            stopServer()
            
        case "server":
            print("Starting Helper Tool Socket Server...")
            helper.startServer()
            
        case "download", "-d":
            if CommandLine.arguments.count > 2 {
                let url = CommandLine.arguments[2]
                let success = helper.downloadVideo(url: url)
                if success {
                    print("✅ Direct download completed successfully")
                } else {
                    print("❌ Direct download failed")
                }
            } else {
                print("Usage: vdh download <URL> or vdh -d <URL>")
            }

        case "input", "-i", "send":
            if CommandLine.arguments.count > 2 {
                let url = CommandLine.arguments[2]
                print("Sending download request via Unix socket...")
                if sendToSocket(url: url) {
                    print("Request sent successfully")
                } else {
                    print("Failed to send request")
                }
            } else {
                print("Usage: vdh input <URL> or vdh -i <URL>")
            }
            
        case "status":
            print("📊 Checking VDH server status...")
            checkServerStatus()
            
        case "task":
            if CommandLine.arguments.count > 2 {
                let taskId = CommandLine.arguments[2]
                print("Getting task details for ID \(taskId)...")
                if sendTaskQuery(taskId: taskId) {
                    print("Task query completed")
                } else {
                    print("Failed to get task details - make sure server is running")
                }
            } else {
                print("Usage: vdh task <ID>")
            }
            
        case "list", "ls":
            print("Getting recent tasks list...")
            if sendListQuery() {
                print("List query completed")
            } else {
                print("Failed to get task list - make sure server is running")
            }
            
        case "cleanup":
            print("Cleaning up old completed tasks...")
            let helper = VideoDownloaderHelper()
            let deletedCount = helper.dbManager.cleanupOldTasks()
            print("Cleanup completed: \(deletedCount) old tasks removed")
            
        case "stats":
            print("Getting task statistics...")
            let helper = VideoDownloaderHelper()
            let stats = helper.dbManager.getTaskStats()
            print("📊 Task Statistics:")
            for status in TaskStatus.allCases {
                let count = stats[status] ?? 0
                let emoji = helper.getStatusEmoji(status)
                print("  \(emoji) \(status.rawValue.capitalized): \(count)")
            }
            let total = stats.values.reduce(0, +)
            print("  📋 Total: \(total)")
            
        case "test":
            print("Testing Unix socket communication...")
            let testUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            if sendToSocket(url: testUrl) {
                print("Socket test completed successfully")
            } else {
                print("Socket test failed")
            }
            
        case "--help", "-h", "help":
            printHelp()
            
        case "--version", "-v", "version":
            print("VDH (Video Downloader Helper) v2.0.0")
            print("Unix Socket-based video downloader with SQLite database and queue management")
            print("Features: Task persistence, status tracking, queue recovery")
            
        default:
            print("Unknown command: \(command)")
            print("Use 'vdh --help' for usage information")
        }
    } else {
        printHelp()
    }
}


func printHelp() {
    print("VDH (Video Downloader Helper) v2.0.0")
    print("Unix Socket-based video downloader with SQLite database and queue management")
    print("")
    print("USAGE:")
    print("  vdh [COMMAND] [OPTIONS]")
    print("")
    print("COMMANDS:")
    print("  start                      Start VDH server in background")
    print("  stop                       Stop running VDH server")
    print("  status                     Check VDH server and queue status")
    print("  server                     Start Unix socket server (foreground)")
    print("  download <URL>, -d <URL>   Download single video directly")
    print("  input <URL>, -i <URL>      Send download request to running server")
    print("  task <ID>                  Get details for specific task ID")
    print("  list, ls                   List recent tasks")
    print("  stats                      Show task statistics")
    print("  cleanup                    Remove old completed tasks (30+ days)")
    print("  test                       Test socket communication")
    print("  help, --help, -h           Show this help message")
    print("  version, --version, -v     Show version information")
    print("")
    print("DATABASE FEATURES:")
    print("  • Persistent task storage with SQLite3")
    print("  • Task status tracking (queued/downloading/completed/failed)")
    print("  • Automatic task recovery on server restart")
    print("  • Task ID management for easy reference")
    print("  • File path recording for completed downloads")
    print("")
    print("QUEUE MANAGEMENT:")
    print("  • Max concurrent downloads: 2 (configurable)")
    print("  • Additional requests will be queued")
    print("  • Downloads process in FIFO order")
    print("  • Real-time status monitoring")
    print("")
    print("EXAMPLES:")
    print("  # Start the server in background")
    print("  vdh start")
    print("")
    print("  # Check server status")
    print("  vdh status")
    print("")
    print("  # Send download requests (returns task ID)")
    print("  vdh input 'https://youtube.com/watch?v=abc123'")
    print("  vdh -i 'https://youtube.com/watch?v=def456'")
    print("")
    print("  # Check specific task status")
    print("  vdh task abc123def456")
    print("")
    print("  # List recent tasks")
    print("  vdh list")
    print("")
    print("  # Check statistics")
    print("  vdh stats")
    print("")
    print("  # Stop the server")
    print("  vdh stop")
    print("")
    print("  # Direct download (skip queue)")
    print("  vdh -d 'https://youtube.com/watch?v=ghi789'")
    print("")
    print("  # Cleanup old tasks")
    print("  vdh cleanup")
    print("")
    print("HOMEBREW INTEGRATION:")
    print("  # Install via Homebrew")
    print("  brew install vdh")
    print("")
    print("  # Start as background service")
    print("  brew services start vdh")
    print("")
    print("  # Check service status")
    print("  brew services list | grep vdh")
    print("")
    print("DATABASE LOCATION:")
    print("  ~/.vdh/video_downloader.db")
    print("")
    print("For more information, visit: https://github.com/yourusername/vdh")
}

main()
