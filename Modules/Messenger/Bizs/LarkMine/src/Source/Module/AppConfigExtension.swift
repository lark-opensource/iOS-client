//
//  AppConfigExtension.swift
//  LarkMine
//
//  Created by liuwanlin on 2020/3/12.
//

import Foundation
import SuiteAppConfig

enum FeatureKey: String {
    case favorite = "favorite"
    case wallet = "chat.hongbao"
}

extension AppConfigManager {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}
