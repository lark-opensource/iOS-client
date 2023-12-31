//
//  SwiftBridge.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/12/3.
//

import Foundation
import RustPB
import RustSDK
import LarkRustHTTP

@objcMembers
public final class SwiftBridge: NSObject {

    /// 获取可靠的服务器时间，服务时间不可靠则返回 0
    public static func ntpTime() -> TimeInterval {
        let ntpTime = Double(get_ntp_time()) / 1000.0
        let systemUptime = ProcessInfo.processInfo.systemUptime
        // 可靠性原理分析见：https://bytedance.feishu.cn/docs/doccnVOdTYqz9PYQdepZsNPB4iv#
        let aTimeBeforeSystemUpTime: TimeInterval = 60 * 60 * 24 * 365 * 30
        guard (ntpTime - systemUptime) > aTimeBeforeSystemUpTime else {
            return 0
        }
        return ntpTime
    }

    public static func metricsForTask(task: URLSessionTask) -> [HttpMetrics] {
        return task.rustMetrics.map { (metric) -> HttpMetrics in
            let metricInfo = HttpMetrics()
            metricInfo.fetchStartDate = metric.fetchStartDate
            metricInfo.dnsCost = metric.dnsCost
            metricInfo.connectionCost = metric.connectionCost
            metricInfo.tlsCost = metric.tlsCost
            metricInfo.totalCost = metric.totalCost
            metricInfo.receiveHeaderDate = metric.receiveHeaderDate
            metricInfo.fetchEndDate = metric.fetchEndDate
            return metricInfo
        }
    }

}

@objcMembers
public final class HttpMetrics: NSObject {
    public var fetchStartDate: Date?
    public var dnsCost: TimeInterval = 0
    public var connectionCost: TimeInterval = 0
    public var tlsCost: TimeInterval = 0
    public var totalCost: TimeInterval = 0
    public var receiveHeaderDate: Date?
    public var fetchEndDate: Date?
}
