//
//  AppConfigExtension.swift
//  LarkFile
//
//  Created by 姚启灏 on 2020/3/12.
//

import Foundation
import SuiteAppConfig

enum FeatureKey: String {
    case sso
}

extension AppConfigService {

    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}
