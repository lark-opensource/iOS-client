// longweiwei

import Foundation

public protocol MailLoggerHandler: AnyObject {
    func handleMailLogEvent(_ event: MailLogEvent)
}

class MailLogger {
    static let shared = MailLogger()

    fileprivate weak var handler: MailLoggerHandler?

    fileprivate var level: MailLogLevel = .debug

    // 限定输出登记，Handler，flag 设置是否输出时间和日志
    class func setLogger(_ level: MailLogLevel, handler: MailLoggerHandler?, flag: Bool) {
        shared.level = level
        shared.handler = handler

        if flag {
            openTimeAndThreadOutput()
        } else {
            closeTimeAndThreadOutput()
        }
    }

    class func openTimeAndThreadOutput() {
        shared.enableTimeOutput = true
        shared.enableThreadOutput = true
    }

    class func closeTimeAndThreadOutput() {
        shared.enableTimeOutput = false
        shared.enableThreadOutput = false
    }

    /*
     其实很多日志上报系统都包含时间输出,
     这个中间层还写一次时间是为了防止日志上报系统可能没有时间的情况,
     为了兼顾性能,所以默认关闭输出到外部
     */
    fileprivate var enableTimeOutput: Bool // 时间输出
    fileprivate var enableThreadOutput: Bool // 线程输出

    fileprivate init() {
        self.enableTimeOutput = false
        self.enableThreadOutput = false
    }
}

// MARK: 对内使用的 log 方法
extension MailLogger {
    class func info(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: .info,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    class func verbose(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: .verbose,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    class func debug(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: .debug,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    class func warning(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: .warning,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    class func error(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: .error,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    class func severe(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: .severe,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    class func log(
        level: MailLogLevel,
        message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        time: TimeInterval? = nil,
        thread: Thread? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let event = MailLogEvent(
            level: level,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: time,
            thread: thread,
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }

    fileprivate func currentTime() -> TimeInterval? {
        if self.enableTimeOutput {
            return Date().timeIntervalSince1970
        } else {
            return nil
        }
    }

    fileprivate func currentThread() -> Thread? {
        if self.enableThreadOutput {
            return Thread.current
        } else {
            return nil
        }
    }

    private func log(_ event: MailLogEvent) {
        if event.level.rawValue >= self.level.rawValue { // 只允许某个 Level 以上输出
            MailLogger.shared.handler?.handleMailLogEvent(event)
        }
    }
}

// MARK: data track log
extension MailLogger {
    private static let kExtraInfoKey = "DataFlow"
    private enum DataFlowType: String {
        case rustPush
    }

    static func dataTrack(change: MailDataTrackLogable) {
        MailLogger.info(change.dataInfo,
                        extraInfo: [kExtraInfoKey: DataFlowType.rustPush.rawValue])
    }
}

// MARK: 数据结构
public struct MailLogEvent {
    public let level: MailLogLevel
    public let message: String
    public let extraInfo: [String: Any]?
    public let error: Error?
    public let component: String?

    // 一般情况下，下面属性不用自定义
    public let time: TimeInterval?
    public let thread: Thread?
    public let fileName: String
    public let funcName: String
    public let funcLine: Int
}

public enum MailLogLevel: Int {
    case debug      // 调试，仅在开发期间有用的调试信息，会上报到日志文件
    case verbose    // 详细，输出显示所有日志消息，包括时间和线程，会上报到日志文件

    case info       // 信息，会上报到日志文件

    case warning    // 警告，会上报到日志文件，而且会上报到 Sentry
    case error      // 错误，会上报到日志文件，而且会上报到 Sentry
    case severe     // 严重，会上报到日志文件，而且会上报到 Sentry

    public var mark: String { // 输出标识，方便阅读
        switch self {
        case .info:
            return "[LarkMail] [INFO]"
        case .verbose:
            return "[LarkMail] [VERBOSE]"
        case .debug:
            return "[LarkMail] [DEBUG]"
        case .warning:
            return "[LarkMail] [WARNING]"
        case .error:
            return "[LarkMail] [ERROR]"
        case .severe:
            return "[LarkMail] [SEVERE]"
        }
    }
}
