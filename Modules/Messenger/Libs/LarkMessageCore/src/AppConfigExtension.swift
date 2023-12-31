//
//  AppConfigExtension.swift
//  LarkMessageCore
//
//  Created by 姚启灏 on 2020/3/25.
//

import Foundation
import SuiteAppConfig
import LarkDebugExtensionPoint

enum FeatureKey: String {
    case secrectChat = "secretChat"
    case messageAction = "chat.messageAction"
}

extension AppConfigManager {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}

public extension Feature {
    static var isDebugMode = false
}
