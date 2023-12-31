//
//  SetupLoggerTask.swift
//  CalendarDemo
//
//  Created by bytedance on 2022/1/27.
//

import UIKit
import Foundation
import Logger
import BootManager
import LKCommonsLogging
import CalendarFoundation
import LarkFoundation
import Calendar

class SetupLoggerTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupLoggerTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        var appenders: [Appender] = [SetupLoggerTask.createCacheFileAppender()]
        #if DEBUG
        appenders.append(SetupLoggerTask.createConsoleAppender())
        #endif
        Logger.setup(appenders: appenders)
        LKCommonsLogging.Logger.setup { (type, category) -> LKCommonsLogging.Log in
            return  DemoLoggerProxy(type, category)
        }
    }
    
    private static func createCacheFileAppender() -> Appender {
        func logRootPath() -> String {
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            return "\(paths[0])/logs"
        }

        let config: DemoCacheFileConfig = DemoCacheFileConfig(rootPath: logRootPath())
        return DemoCacheFileAppender(config)
    }
    
    private static func createConsoleAppender() -> Appender {
        let config = XcodeConsoleConfig(logLevel: .debug)
        return LoggerConstruct.createConsoleAppender(config: config)
    }
    
}

struct DemoLoggerProxy: LKCommonsLogging.Log {
    let logger: LoggerLog
    let custom: LKCommonsLogging.Log?
    private let lock = NSLock()

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.logger = Logger.log(typeCls, category: category)
        self.custom = custom
    }

    func log(event: LKCommonsLogging.LogEvent) {
        lock.lock(); defer { lock.unlock() }
        let en = DemoEventTransform.transform(event)
        logger.log(en)
        self.custom?.log(event: event)
    }

    func isDebug() -> Bool {
        return true
    }

    func isTrace() -> Bool {
        return true
    }
}


struct DemoEventTransform {
    static func transform(_ event: LKCommonsLogging.LogEvent) -> LoggerLogEvent {
        return LoggerLogEvent(
            logId: event.logId,
            time: event.time,
            tags: event.tags,
            level: LogLevel(rawValue: event.level) ?? LogLevel.fatal,
            message: event.message,
            thread: event.thread,
            file: event.file,
            function: event.function,
            line: event.line,
            error: event.error,
            params: event.params
        )
    }
}

public struct DemoCacheFileConfig {

    public var rootPath: String
    public var buffer: UInt
    public var timeInterval: TimeInterval
    public var logCacheNumber: UInt

    public init(
        rootPath: String,
        buffer: UInt = 10 * 1024,
        timeInterval: TimeInterval = 30,
        logCacheNumber: UInt = 5) {
        self.rootPath = rootPath
        self.buffer = buffer
        self.timeInterval = timeInterval
        self.logCacheNumber = logCacheNumber
    }
}

public class DemoCacheFileAppender: NSObject, Appender {
    private let writeQueue: OperationQueue

    private var cache: Data
    private let _cacheLock = DispatchSemaphore(value: 1)

    private static let dateFormatter: DateFormatter = DateFormatter()

    private static let eventDateFormatter: DateFormatter = DateFormatter()

    private let buffer: UInt // 写入 log buffer

    private let dayLong: TimeInterval = 24 * 60 * 60

    private var currentHandlerFunc: (() -> FileHandle?)?

    private var timer: Timer?

    private let timeInterval: TimeInterval // 写入 log timer 间隔

    private var rootPath: String // 日志根目录

    private var logCacheNumber: UInt // 日志缓存天数

    init(_ config: DemoCacheFileConfig) {
        assert(config.logCacheNumber > 0, "log cache number must > 0")
        assert(config.timeInterval > 0, "timer interval must > 0")

        self.rootPath = config.rootPath
        self.buffer = config.buffer
        self.timeInterval = config.timeInterval
        self.logCacheNumber = config.logCacheNumber

        DemoCacheFileAppender.dateFormatter.dateFormat = "YYYY-MM-dd"
        DemoCacheFileAppender.eventDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        self.cache = Data()
        self.writeQueue = OperationQueue()
        self.writeQueue.maxConcurrentOperationCount = 1
        super.init()
        self.currentHandlerFunc = self.generateHandlerGenerator()
        self.createLogDirIfNeeded()
        self.registAppStateChangeNotification()
        self.timer = Timer.scheduledTimer(withTimeInterval: config.timeInterval, repeats: true, block: { [weak self] (_) in
            self?.writeCacheDataToFile()
        })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public static func identifier() -> String {
        return "CacheFileAppender"
    }

    public func persistent(status: Bool) {
    }

    public static func persistentStatus() -> Bool {
        return false
    }

    public func doAppend(_ event: LoggerLogEvent) {
        printEvent(event)
    }

    public func commit() {
        writeCacheDataToFile()
    }

    func printEvent(_ event: LoggerLogEvent) {
        let fileUrl = URL(fileURLWithPath: event.file)
        let additionalStr = self.extractAdditionalData(additionalData: event.params ?? [:])
        guard let formatTime = DemoCacheFileAppender.eventDateFormatter.string(for: Date(timeIntervalSince1970: event.time)) else { return }
        let message: Data? = "{\"time\":\"\(formatTime)\",\"message\":\"\(event.message.replacingOccurrences(of: "\"", with: "\\\""))\",\"module_path\":\"\(event.category)\",\"file\":\"\(fileUrl.lastPathComponent)\",\"line\":\(event.line),\"level\":\"\(String(describing: event.level).uppercased())\",\"target\":\"\(event.function)\",\"thread\":\"\(event.thread)\",\"process_name\":\"lark\",\"client_os\":\"ios\"}\n".data(using: .utf8)
        _cacheLock.wait()
        guard let msg = message else { return }
        cache.append(msg)
        let cacheCount = cache.count
        _cacheLock.signal()
        if cacheCount >= buffer {
            writeCacheDataToFile()
        }

    }

    func writeCacheDataToFile() {
        _cacheLock.wait()
        let theCache = self.cache
        self.cache.removeAll()
        _cacheLock.signal()
        writeQueue.addOperation { [weak self] in
            if let handlerProvider = self?.currentHandlerFunc,
                let handler = handlerProvider() {
                handler.write(theCache)
            }
        }
    }

    func generateHandlerGenerator() -> () -> FileHandle? {
        var handler: FileHandle?
        var timestamp = Date.timeIntervalSinceReferenceDate
        return {
            //大于24小时
            if handler == nil || Date.timeIntervalSinceReferenceDate - timestamp > self.dayLong {
                if handler != nil {
                    handler?.closeFile()
                    handler = nil
                }
                handler = self.getCurrentHandler()
                handler?.seekToEndOfFile()
                timestamp = Date.timeIntervalSinceReferenceDate
                self.cleanOldFiles()
            }
            return handler
        }
    }

    func getCurrentHandler() -> FileHandle? {
        return self.getFileNameByDay(Date())
    }

    func getCurrentFileName(_ date: Date = Date()) -> String {
        let dateStr = DemoCacheFileAppender.dateFormatter.string(from: date)
        return "larkthoth-0-\(dateStr).alaudalog.log"
    }

    func getFileNameByDay(_ date: Date) -> FileHandle? {
        let dirPath = self.getLogDir()
        let logFile = "\(dirPath)/\(getCurrentFileName(date))"
        if !FileManager.default.fileExists(atPath: logFile) {
            FileManager.default.createFile(atPath: logFile, contents: nil, attributes: nil)
        }
        return FileHandle(forWritingAtPath: logFile)
    }

    func getLogDir() -> String {
        if self.rootPath.hasSuffix("/") {
            return "\(rootPath)"
        } else {
            return "\(rootPath)/"
        }
    }

    func createLogDirIfNeeded() {
        let dirPath = self.getLogDir()
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                assertionFailure("Log path is illegally, error \(error)")
            }
        } else if !isDirectory.boolValue {
            assertionFailure("Log path is illegally, log path is not directory")
        }
    }

    func registAppStateChangeNotification() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(applicationEnterBackgroundOrTerminate(notification:)),
                       name: UIApplication.didEnterBackgroundNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(applicationEnterBackgroundOrTerminate(notification:)),
                       name: UIApplication.willTerminateNotification,
                       object: nil)
    }

    @objc
    func applicationEnterBackgroundOrTerminate(notification: NSNotification) {
        writeCacheDataToFile()
    }

    func cleanOldFiles() {
        let logDir = self.getLogDir()
        do {
            let paths = try FileManager.default.contentsOfDirectory(atPath: logDir)
            if paths.count > logCacheNumber {
                var cleanFiles = paths.sorted()
                cleanFiles.removeSubrange((paths.count - Int(logCacheNumber))..<paths.count)
                try cleanFiles.forEach({ (path) in
                    try FileManager.default.removeItem(atPath: "\(logDir)/\(path)")
                })
            }
        } catch {
        }
    }
}
