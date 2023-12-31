//
//  MonitorTool.swift
//  LarkAppStateSDK
//
//  Created by tujinqiu on 2019/8/12.
//

import Foundation
import LKCommonsTracker

class MonitorEvent {
    fileprivate static let durationKey = "duration"
    fileprivate static let resultTypeKey = "resultType"
    fileprivate static let errorCodeKey = "errorCode"
    fileprivate static let errorMsgKey = "errorMsg"
    fileprivate static let successValue = "success"
    fileprivate static let failValue = "fail"
    fileprivate static let netStatusKey = "netStatus"
    fileprivate static let networkTypeKey = "networkType"

    fileprivate var metricData = [String: Any]()
    fileprivate var categoryData = [String: Any]()
    fileprivate var name: String
    private var startTime: Date

    init(name: String) {
        self.name = name
        self.startTime = Date()
    }

    private func addCategoryKeyValue(_ key: String, _ value: Any) -> MonitorEvent {
        categoryData[key] = value
        return self
    }

    func addSuccess() -> MonitorEvent {
        return addCategoryKeyValue(MonitorEvent.resultTypeKey, MonitorEvent.successValue)
    }

    func addFail() -> MonitorEvent {
        return addCategoryKeyValue(MonitorEvent.resultTypeKey, MonitorEvent.failValue)
    }

    func addError(_ errorCode: Int, _ errorMsg: String) -> MonitorEvent {
        return addCategoryKeyValue(MonitorEvent.errorCodeKey, errorCode).addCategoryKeyValue(MonitorEvent.errorMsgKey, errorMsg)
    }

    private func addMetricKeyValue(_ key: String, _ value: Any) -> MonitorEvent {
        metricData[key] = value
        return self
    }

    private func addDuration(_ duration: TimeInterval) -> MonitorEvent {
        return addMetricKeyValue(MonitorEvent.durationKey, duration)
    }

    func addDuration() -> MonitorEvent {
        let duration = -startTime.timeIntervalSinceNow
        return addDuration(duration)
    }
    
    func setSnapshotId(_ value: String?) -> MonitorEvent {
        addCategoryKeyValue("snapshot_id", value)
    }

    func flush() {
        let envType = OpenPlatformUtil.getEnvType()
        if envType == .staging {
            return
        }

        categoryData[MonitorEvent.netStatusKey] = OpenPlatformUtil.getNetStatus()
        categoryData[MonitorEvent.networkTypeKey] = OpenPlatformUtil.getNetworkType()

        let metricDataImutable = metricData
        let categoryDataImutable = categoryData

        Tracker.post(SlardarEvent(
            name: name,
            metric: metricDataImutable,
            category: categoryDataImutable,
            extra: [:])
        )
    }
}

// 事件名称写到这里
extension MonitorEvent {
    static let terminalinfo_settings_result = "app_states_terminalinfo_settings_result"
    static let terminalinfo_upload_result = "app_states_terminalinfo_upload_result"
    static let terminalinfo_location = "app_states_terminalinfo_location"
    static let terminalinfo_wifi = "app_states_terminalinfo_wifi"
}
