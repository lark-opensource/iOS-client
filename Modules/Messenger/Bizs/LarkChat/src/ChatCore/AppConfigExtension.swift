//
//  AppConfigExtension.swift
//  LarkChat
//
//  Created by liuwanlin on 2020/3/12.
//

import Foundation
import SuiteAppConfig

enum FeatureKey: String {
    case messageAction = "chat.messageAction"
    case chatApps = "chat.apps"
    case messagePull = "message.pull"
    case wallet = "chat.hongbao"
    case chatMenu = "chat.chatMenu"
}

extension AppConfigManager {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}

extension AppConfigService {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}
