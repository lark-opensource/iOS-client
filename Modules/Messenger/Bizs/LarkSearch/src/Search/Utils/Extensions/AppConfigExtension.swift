//
//  AppConfigExtension.swift
//  LarkSearch
//
//  Created by 袁平 on 2021/2/23.
//

import Foundation
import SuiteAppConfig

enum FeatureKey: String {
    case history = "search.history"
    case searchByType = "search.searchByType"
}

extension AppConfigManager {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }

    func exist(for key: FeatureKey) -> Bool {
        return exist(for: key.rawValue)
    }
}

extension AppConfigService {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}
