import Foundation

/// 日志工具：按天写文件到 ~/Library/Logs/DrinkWater/
enum AppLog {
    /// 获取日志目录路径
    static var logDirectory: String {
        let home = NSHomeDirectory()
        return home + "/Library/Logs/DrinkWater"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    /// 确保日志目录存在
    private static func ensureLogDir() -> String {
        let dir = logDirectory
        if !FileManager.default.fileExists(atPath: dir) {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 写入一条日志
    static func log(_ tag: String, _ message: String) {
        let date = Date()
        let dateStr = dateFormatter.string(from: date)
        let timeStr = timeFormatter.string(from: date)
        let line = "[\(timeStr)] [\(tag)] \(message)\n"
        let dir = ensureLogDir()
        let filePath = "\(dir)/\(dateStr).log"
        // 追加写入
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: filePath) {
                if let handle = FileHandle(forWritingAtPath: filePath) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: filePath, contents: data)
            }
        }
        // 同时输出到 stderr
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
