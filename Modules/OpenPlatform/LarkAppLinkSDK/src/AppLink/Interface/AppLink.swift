//
//  LarkInerface+AppLink.swift
//  LarkInterface
//
//  Created by yinyuan on 2019/8/25.
//

import Foundation
import UIKit
import EENavigator
import LarkFeatureGating
import LarkSetting

// swiftlint:disable identifier_name
public struct AppLinkBody: CodableBody {
    // Regex: //(applink\\.feishu\\.cn|applink\\.larksuite\\.com)/
    private static let prefix: String = {
        // 新的 AppLink 开始支持动态域名，直接通配以下规则 //applink.*
       
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.applink.v3") {
             return "//(applink|applink\\.|go\\.)"
        } else {
            return "//(applink|applink\\.)"
        }
    }()

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: prefix, type: .regex)
    }

    public var _url: URL {
        return URL(string: AppLinkBody.prefix)!
    }

    /// Read from plist /AppLink/Domains/
    public static var domains: [String]? = {
        guard let appLinkConfig = Bundle.main.infoDictionary?["AppLink"] as? [String: Any] else {
            return nil
        }
        return appLinkConfig["Domains"] as? [String]
    }()
}
// swiftlint:enable identifier_name
