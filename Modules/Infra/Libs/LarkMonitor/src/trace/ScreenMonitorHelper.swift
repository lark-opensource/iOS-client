//
//  ScreenMonitorHelper.swift
//  LarkMonitor
//
//  Created by aslan on 2021/11/11.
//

import Foundation
import LarkSetting
import LKCommonsLogging
import LarkSecurityAudit
import LarkAccountInterface
import LarkReleaseConfig

public enum MonitorEventType {
    case screenShot
    case screenRecording
}

private let LKSettingFieldName = UserSettingKey.make(userKeyLiteral: "lark_screen_page_configs")
private let logger = Logger.log(ScreenMonitorHelper.self)

final class ScreenMonitorHelper {
    static public func auditEvent(currentPage: String, eventType: MonitorEventType) {
        guard ReleaseConfig.isKA else {
            /// 只有ka租户才上报
            logger.info("ScreenshotMonitor type: \(eventType), is not ka account")
            return
        }
        if let settingConfig = try? SettingManager.shared.setting( //Global
            with: LKSettingFieldName
        ) as? [String: String] {
            if let pageName = settingConfig[currentPage] as String? {
                logger.info("ScreenshotMonitor type: \(eventType), match page: \(currentPage): \(pageName)")
                let securityAudit = SecurityAudit()
                var event = Event()
                event.module = .moduleDevice
                event.env.did = AccountServiceAdapter.shared.deviceService.deviceId //Global
                event.env.client = .clientIos
                let operation = transformEventType(enventType: eventType)
                event.operation = operation
                event.operator = OperatorEntity()
                event.operator.type = .entityUserID
                event.operator.value = AccountServiceAdapter.shared.currentChatterId //Global
                var opType = SecurityEvent_ObjectEntity()
                opType.type = .entityDevice
                opType.value = "0"
                var detail = SecurityEvent_ObjectDetail()
                detail.currentPage = pageName
                opType.detail = detail
                event.objects = [opType]
                securityAudit.auditEvent(event)
            } else {
                logger.info("ScreenshotMonitor type: \(eventType), not match page: \(currentPage)")
            }
        } else {
            logger.info("ScreenshotMonitor type: \(eventType), not fetch settings")
        }
    }

    static func transformEventType(enventType: MonitorEventType) -> SecurityEvent_OperationType {
        switch enventType {
        case .screenShot:
            return .operationScreenShot
        case .screenRecording:
            return .operationScreenRecording
        }
    }
}
