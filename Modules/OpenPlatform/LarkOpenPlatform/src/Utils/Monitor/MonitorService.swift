//
//  MonitorService.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2020/5/24.
//

import Foundation
import LarkOPInterface
import LKCommonsTracker
import LKCommonsLogging

/// OPMonitor 默认 Lark 上报能力实现
final class MonitorServiceReporter: NSObject, OPMonitorReportProtocol {

    /// 埋点上报
    /// - Parameters:
    ///   - name: 事件名
    ///   - metrics: 统计值类型数据集合
    ///   - categories: 枚举/分类类型数据集合
    public func report(withName name: String, metrics: [String: Any]?, categories: [String: Any]?, platform: LarkOPInterface.OPMonitorReportPlatform) {

        if(platform.contains(.slardar)) {
            // 上报到 Sladar
            Tracker.post(SlardarEvent(
                name: name,
                metric: metrics ?? [:],
                category: categories ?? [:],
                extra: [:])
            )
        }

        if (platform.contains(.tea)) {
            // 上报到 Tea
            var params: [String: Any] = [:]
            if let metrics = metrics {
                params.merge(metrics) { (_, new) in new }
            }
            if var categories = categories {
                if (!categories.keys.contains("solution_id")) {
                    categories["solution_id"] = "none"
                }
                if (categories.keys.contains("solution_id") && categories["solution_id"] as? String == "") {
                    categories["solution_id"] = "none"
                }
                params.merge(categories){(_, new) in new}
            }
            Tracker.post(TeaEvent(name, params: params))
        }

    }
}

/// OPMonitor 默认 Lark 日志能力实现
final class MonitorServiceLogger: NSObject, OPMonitorLogProtocol {

    /// lark 日志
    private static let logger = Logger.oplog(MonitorServiceLogger.self, category: OPMonitorConstants.default_log_tag)

    /// 日志打印
    /// - Parameters:
    ///   - level: 日志级别
    ///   - tag: 标签
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    ///   - content: 日志内容
    public func log(with level: OPMonitorLogLevel, tag: String?, file: String?, function: String?, line: Int, content: String?) {
        let logContent = content ?? ""
        let file = file ?? ""
        let function = function ?? ""
        let tagValue = tag ?? ""
        let logIdValue = tag ?? ""
        switch level {
        case .debug:
            MonitorServiceLogger.logger.debug(logId: logIdValue, logContent, tags: [tagValue], file: file, function: function, line: line)
        case .info:
            MonitorServiceLogger.logger.info(logId: logIdValue, logContent, tags: [tagValue], file: file, function: function, line: line)
        case .warn:
            MonitorServiceLogger.logger.warn(logId: logIdValue, logContent, tags: [tagValue], file: file, function: function, line: line)
        case .error, .fatal:
            // Lark 日志没有 fatal 级别，用 error 级别代替
            MonitorServiceLogger.logger.error(logId: logIdValue, logContent, tags: [tagValue], file: file, function: function, line: line)
        default:
            MonitorServiceLogger.logger.info(logId: logIdValue, logContent, tags: [tagValue], file: file, function: function, line: line)
        }
    }
}
