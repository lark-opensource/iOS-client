//
//  GDMonitorService.swift
//  Timor
//
//  Created by yinyuan on 2020/5/22.
//

import Foundation
import ECOProbe
import ECOInfra

/// Gadget 定制 monitor service
@objcMembers
public final class GDMonitorService: OPMonitorService {

    /// Gadget 默认 service 实例
    public static let gadgetMonitorService = GDMonitorService(config: nil)

    private let reporter = GDMonitorServiceReporter()
    private let logger = GDMonitorServiceLogger()

    /// 初始化一个 GDMonitorService
    /// - Parameters:
    ///   - config: 指定 config，如果不指定则使用 Gadget 默认 config
    public override init(config: OPMonitorServiceConfig?) {
        super.init(config: config)
        if config == nil {
            self.config = OPMonitorServiceConfig(reportProtocol: reporter, logProtocol: logger)
        }
    }

    public override func log(_ monitor: OPMonitorEvent) {
        // monitor 日志非 trace 级别在上层输出(兼容旧埋点)

        // trace 级别日志正常输出
        if monitor.level() == OPMonitorLevelTrace {
            super.log(monitor)
        }
    }
}

class GDMonitorServiceReporter: NSObject, OPMonitorReportProtocol {

    public func report(withName name: String, metrics: [String : Any]?, categories: [String : Any]?, platform: OPMonitorReportPlatform) {
        guard let monitorPlugin = BDPTimorClient.shared().monitorPlugin.sharedPlugin() as? BDPMonitorPluginDelegate else {
            BDPLogError(tag: .gadget, "monitorPlugin is nil")
            return
        }
        // 对接到BDP埋点
        monitorPlugin.bdp_monitorEventName?(name, metric: metrics, category: categories, extra: nil, platform: platform)
    }
}

class GDMonitorServiceLogger: NSObject, OPMonitorLogProtocol {
    public func log(with level: OPMonitorLogLevel, tag: String?, file: String?, function: String?, line: Int, content: String?) {
        // 对接到BDP日志
        let tag = BDPTagEnum(rawValue: tag ?? "") ?? .gadget
        switch level {
        case .debug:
            BDPLogDebug(tag: tag, fileName: file ?? #fileID, functionName: function ?? #function, line: line>0 ? line : #line, content ?? "")
        case .warn:
            BDPLogWarn(tag: tag, fileName: file ?? #fileID, functionName: function ?? #function, line: line>0 ? line : #line, content ?? "")
        case .error, .fatal:
            BDPLogError(tag: tag, fileName: file ?? #fileID, functionName: function ?? #function, line: line>0 ? line : #line, content ?? "")
        default:
            BDPLogInfo(tag: tag, fileName: file ?? #fileID, functionName: function ?? #function, line: line>0 ? line : #line, content ?? "")
        }
    }
}
