//
//  DocsLogger.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/8/10.
//

public protocol DocsLoggerHandler: AnyObject {
    func handleDocsLogEvent(_ event: DocsLogEvent)
}
// nolint: duplicated_code
public final class DocsLogger: NSObject {
    static let shared = DocsLogger()

    fileprivate weak var handler: DocsLoggerHandler?

    fileprivate var level: DocsLogLevel = .debug

    // 限定输出登记，Handler，flag 设置是否输出时间和日志
    public class func setLogger(_ level: DocsLogLevel, handler: DocsLoggerHandler?, flag: Bool) {
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

    fileprivate override init() {
        self.enableTimeOutput = false
        self.enableThreadOutput = false
    }
}

// MARK: 对内使用的 log 方法
extension DocsLogger {
    @objc
    public class func info(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
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

    public class func verbose(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
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

    public class func debug(
        _ message: @autoclosure () -> String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
#if DEBUG
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
            level: .debug,
            message: message(),
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: shared.currentTime(),
            thread: shared.currentThread(),
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
#endif
    }

    public class func warning(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
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

    public class func error(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
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

    public class func severe(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
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

    public class func log(
        level: DocsLogLevel,
        message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        traceId: String? = nil,
        time: TimeInterval? = nil,
        useCustomTimeStamp: Bool = false,
        thread: Thread? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        let extraInfo = addTraceIdToExtraInfo(traceId: traceId, extraInfo: extraInfo)
        let event = DocsLogEvent(
            level: level,
            message: message,
            extraInfo: extraInfo,
            error: error,
            component: component,
            time: time,
            useCustomTimeStamp: useCustomTimeStamp,
            thread: thread,
            fileName: fileName,
            funcName: funcName,
            funcLine: funcLine)
        shared.log(event)
    }
    
    fileprivate class func addTraceIdToExtraInfo(traceId: String?, extraInfo: [String: Any]?) -> [String: Any]? {
        if let traceId = traceId {
            var extraInfo = extraInfo ?? [:]
            extraInfo.updateValue(traceId, forKey: "traceId")
            return extraInfo
        } else {
            return extraInfo
        }
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

    private func log(_ event: DocsLogEvent) {
        if SKFoundationConfig.shared.isBeingTest {
            print("\(event.fileName) \(event.message), \(String(describing: event.extraInfo)), \(event.component ?? "")")
        }
        // 只允许某个 Level 以上输出
        guard event.level.rawValue >= self.level.rawValue else {
            return
        }
        
        SecurityInfoChecker.shared.encryptLogIfNeed(event) {
            DocsLogger.shared.handler?.handleDocsLogEvent($0)
            
            #if DEBUG
            if event.level.rawValue > DocsLogLevel.verbose.rawValue {
                SecurityInfoChecker.shared.checkLog($0)
            }
            #endif
        }
    }
}



// MARK: 数据结构
public struct DocsLogEvent {
    public let level: DocsLogLevel
    public var message: String
    public var extraInfo: [String: Any]?
    public var error: Error?
    public let component: String?

    // 一般情况下，下面属性不用自定义
    public let time: TimeInterval?
    /// 是否由业务方指定时间戳，默认否(log写入时自动获取)，可在批量log聚合写入时开启(原始时间戳)
    public var useCustomTimeStamp = false
    public let thread: Thread?
    public let fileName: String
    public let funcName: String
    public let funcLine: Int
}

public enum DocsLogLevel: Int {
    case debug      // 调试，仅在开发期间有用的调试信息，会上报到日志文件
    case verbose    // 详细，输出显示所有日志消息，包括时间和线程，会上报到日志文件

    case info       // 信息，会上报到日志文件

    case warning    // 警告，会上报到日志文件，而且会上报到 Sentry
    case error      // 错误，会上报到日志文件，而且会上报到 Sentry
    case severe     // 严重，会上报到日志文件，而且会上报到 Sentry

    public var mark: String { // 输出标识，方便阅读
        switch self {
        case .info:
            return "❤️ [INFO]"
        case .verbose:
            return "💖 [VERBOSE]"
        case .debug:
            return "⭕️ [DEBUG]"
        case .warning:
            return "❓ [WARNING]"
        case .error:
            return "❗️ [ERROR]"
        case .severe:
            return "‼️ [SEVERE]"
        }
    }
}

public enum LogComponents {
    public static let webContextMenu = "==webContextMenu== "
    public static let domain = "==domain== "
    public static let fileOpen = "==openFile== "
    public static let sdkConfig = "==sdkConfig== "
    public static let net = "==NET=="
    public static let dataModel = "==datamodel== "
    public static let watermark = "==watermark== "
    public static let editorPool = "==EditorPool== "
    public static let offlineSyncDoc = "==offlineSyncDoc== "
    public static let db = "==DocsDB== "
    public static let preload = "==Preload== "
    public static let manuOffline = "==manuOffline== "
    public static let metaInfoWatch = "==metaInfoWatch== "
    public static let fileList = "==fileList== "
    public static let wiki = "==wiki== "
    public static let drive = "==drive== "
    public static let excel2HTML = "==excel2HTML== "
    public static let remoteConfig = "==RemoteConfig== "
    public static let larkFeatureGate = "==LarkFG== "
    public static let tracker = "==docsTracker== "
    public static let newCache = "==newCache== "
    public static let docsRN = "==docsRN== "
    public static let comment = "==comment== "
    public static let gadgetComment = "==gadgetComment== "
    public static let bitable = "==bitable=="
    public static let reminder = "==reminder=="
    public static let dbDelay = "==dbDelay=="
    public static let sheetTab = "==sheetTab=="
    public static let sheetDropdown = "==sheetDropdown=="
    public static let sheetAttachmentList = "==sheetAttachmentList=="
    public static let docsImageDownloader = "==docsImageDownloader=="
    public static let vcFollow = "==VCFollow=="
    public static let simpleMode = "==simpleMode=="
    public static let pickImage = "==pickImage=="
    public static let spaceThumbnail = "==SpaceThumbnail== "
    public static let minaConfig = "==minaConfig=="
    public static let shareModule = "==shareModule=="
    public static let permission = "==Permission=="
    public static let uploadImg = "==uploadImg=="
    public static let fePackgeManager = "==fePackgeManager=="
    public static let fePackgeDownload = "==fePackgeDownload=="
    public static let toolbar = "==toolbar=="
    public static let commentPic = "==commentPic=="
    public static let newFGPlatform = "==newFGPlatform=="
    public static let pickFile = "==pickFile== "
    public static let uploadFile = "==uploadFile=="
    public static let docsFeed = "==docsFeed=="
    public static let nativeEditor = "==nativeEditor=="
    public static let atUserPerm = "==atUserPerm=="
    public static let blletinManager = "==blletinManager=="
    public static let docsDetailInfo = "==docsDetailInfo=="
    public static let skRichText = "==skRichText=="
    public static let imgPreview = "==imgPreview=="
    public static let assignee = "==assignee=="
    public static let requireOpen = "==requireOpen=="
    public static let catalog = "==catalog=="
    public static let workspace = "==workspace=="
    public static let lynx = "==docsLynx=="
    public static let clippingDoc = "==clippingDoc=="
    public static let mention = "==mention=="
    public static let cookie = "==cookie=="
    public static let docsException = "==docsException=="
    public static let version = "==docsVersion=="
    public static let btUploadCache = "==btUploadCache=="
    public static let ssrWebView = "==ssrwebview= \(fileOpen)"
    public static let inlineAI = "==inlineAI=="
    public static let template = "==template=="
    public static let permissionSDK = "==PermissionSDK== "
    public static let docComponent = "==docComponent=="
    public static let syncBlock = "==SyncBlock== "
    public static let baseRecommend = "==baseRecommend=="
    public static let baseChart = "==baseChart=="
    public static let fetchSSR = "==fetchSSR== "
    public static let associateApp = "==associateApp== "
    public static let replaceDocOriginUrl = "==replaceDocOriginUrl== "
    public static let translate = "==Translate== "
}
