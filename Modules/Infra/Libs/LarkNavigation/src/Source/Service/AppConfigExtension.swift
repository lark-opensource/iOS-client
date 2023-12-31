//
//  AppConfigExtension.swift
//  LarkNavigation
//
//  Created by KT on 2020/3/12.
//

import Foundation
import SuiteAppConfig

enum FeatureKey: String {
    case navi = "navi"
}

enum TraitKey: String {
    case tabs = "tabs"
}

extension AppConfigManager {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}

extension BaseConfig {
    func trait<T>(for key: TraitKey, decode: ((Any) -> T)? = nil) -> T? {
        return trait(for: key.rawValue, decode: decode)
    }
}
