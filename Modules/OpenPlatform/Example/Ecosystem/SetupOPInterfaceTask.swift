//
//  SetupOPInterfaceTask.swift
//  Ecosystem
//
//  Created by MJXin on 2021/5/7.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import BootManager
import LarkContainer
import RunloopTools
import LarkOPInterface
import LKTracing
import LKCommonsLogging
import EEMicroAppSDK
import Heimdallr
import Swinject
import LarkAssembler

/// OPMonitor 默认 Lark 上报能力实现
public class MonitorServiceReporter: NSObject, OPMonitorReportProtocol {
    public func report(withName name: String, metrics: [String: Any]?, categories: [String: Any]?, platform: OPMonitorReportPlatform) {
        if platform.contains(.slardar) {
            HMDTTMonitor.defaultManager().hmdTrackService(name, metric: metrics as? [String: NSNumber] ?? [:], category: categories ?? [:], extra: [:])
        }
    }
}

/// OPMonitor 默认 Lark 日志能力实现
public class MonitorServiceLogger: NSObject, OPMonitorLogProtocol {
    private lazy var logDateformatter: DateFormatter = {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateformatter
    }()

    /// lark 日志
    private static let logger = Logger.oplog(MonitorServiceLogger.self, category: OPMonitorConstants.default_log_tag)
    
    func log(withLevel level: Int, tag: String!, filename: String!, func_name: String!, line: Int, content: String!, logId: String!) {
        var levelStr: String
        switch level {
        case 1:
            levelStr = "DEBUG"
        case 2:
            levelStr = "INFO"
        case 3:
            levelStr = "⚠️WARN"
        case 4:
            levelStr = "❌ERROR"
        case 5:
            levelStr = "❌ERROR"
        default:
            levelStr = String(level)
        }
        print("\(logDateformatter.string(from: Date())) \(levelStr) [\(tag ?? "") \(logId ?? "")][\(filename ?? ""):\(line)] \(func_name ?? "") \(content ?? "")")
    }

    /// 日志打印
    /// - Parameters:
    ///   - level: 日志级别
    ///   - tag: 标签
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    ///   - content: 日志内容
    public func log(with level: OPMonitorLogLevel, tag: String?, file: String?, function: String?, line: Int, content: String?) {
        log(withLevel: Int(level.rawValue), tag: tag, filename: file, func_name: function, line: line, content: content, logId: "")
    }
}

class SetupOPInterfaceTaskAssembly: LarkAssemblyInterface {
    func registLarkAppLink(container: Swinject.Container) {
        NewBootManager.register(SetupOPInterfaceTask.self)
    }
}

class SetupOPInterfaceTask: FlowBootTask, Identifiable {
    static var identify = "SetupOPInterfaceTask"

    override var delayScope: Scope? { return .container }

    override var scope: Set<BizScope> { return [.openplatform, .docs] }

    @Provider var openPlatformService: OpenPlatformService

    /// monitor 上报能力
    private static var monitorReporter = MonitorServiceReporter()

    /// monitor 日志能力
    private static var monitorLogger = MonitorServiceLogger()

    override func execute(_ context: BootContext) {

        // OPLog 初始化,用于设定 OPLogProxy，以及构造正真的 logger
        // OPLogProxy 只是用于日志审查，并不会实际消费日志，需要再注入 logger 构造方法用于消费审查后的日志
        Logger.setupOPLog { (type, category) -> Log in
            return Logger.log(type, category: "OpenPlatform." + category)
        }

        /// OPTrace 全局初始化
        let config = OPTraceConfig(prefix: LKTracing.identifier) { (parent) -> String in
            return LKTracing.newSpan(traceId: parent)
        }
        OPTraceService.default().setup(config)

        /// OPMonitor 全局初始化
        OPMonitorService.setup(OPMonitorServiceConfig(reportProtocol: SetupOPInterfaceTask.monitorReporter, logProtocol: SetupOPInterfaceTask.monitorLogger))
    }
}
