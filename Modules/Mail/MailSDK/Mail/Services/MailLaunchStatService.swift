//
//  MailLaunchStatService.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/3/9.
//

import Foundation
import Homeric

public final class MailLaunchStatService {
    public enum LaunchActionType: String {
        case larkMailAccountLoaded
        case initAPIWrapper
        case initMailSDK
        case mailManager
        case dataService
        case mailNetConfig
        case updateRustService
    }
    public static let `default` = MailLaunchStatService()
    var actionStartDateMap: [LaunchActionType: Date] = [:]
}

extension MailLaunchStatService {
    public func markActionStart(type: LaunchActionType) {
        let now = Date()
        actionStartDateMap[type] = now
    }

    public func markActionEnd(type: LaunchActionType) {
        guard let start = actionStartDateMap[type] else {
            assertionFailure("can not call end before start")
            return
        }
        let interval = Date().timeIntervalSince(start) * 1000
        var params: [String: Any] = ["action": type.rawValue,
                                      "render_time": interval]
        MailLogger.info("MailSDK Launch markActionEnd ----> \(type.rawValue): \(interval)")
        // TODO: 增加统计类型。
         MailTracker.log(event: Homeric.EMAIL_MAILSDK_LAUNCH_DURATION, params: params)
    }
}
