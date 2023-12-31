//
//  AppConfigExtension.swift
//  LarkContact
//
//  Created by 姚启灏 on 2020/3/12.
//

import Foundation
import SuiteAppConfig

enum FeatureKey: String {
    case contactOrgnization = "contact.organization"
    case contactBots = "contact.bots"
    case contactHelpdesk = "contact.helpdesk"
}

extension AppConfigService {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }
}
