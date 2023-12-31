//
//  WebTranslateAppSettingHelper.swift
//  LarkAI
//
//  Created by ByteDance on 7/3/2023.
//

import Foundation
import LarkSetting
import LarkContainer

class WebTranslateAppSettingHelper {

    struct WebTranslateConfig: SettingDecodable {
        static let settingKey = UserSettingKey.make(userKeyLiteral: "web_translate_config")
        let sampleTextMaxContentLength: Int?
        let domainControl: DomainControl?
    }

    struct DomainControl: Decodable {
        let type: String?
        let hostList: [String]?
        let patternList: [String]?
    }
    private static let TYPE_ALLOW = "allow"
    private static let TYPE_DENY = "deny"
    private static let DEFAULT_RESULT = true
    var webTranslateConfig: WebTranslateConfig?

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.webTranslateConfig = try? userResolver.settings.staticSetting(with: WebTranslateConfig.self)
    }

    func getSampleMaxLength() -> Int? {
        return webTranslateConfig?.sampleTextMaxContentLength
    }

    func isUrlEnable(url: URL?) -> Bool {
        guard let url = url, let host = url.host else {
            return false
        }
        guard let domainControl = webTranslateConfig?.domainControl else {
            // 没获取到黑名单配置默认是true
            return Self.DEFAULT_RESULT
        }
        if domainControl.type != Self.TYPE_ALLOW && domainControl.type != Self.TYPE_DENY {
            return Self.DEFAULT_RESULT
        }
        var hostPath = host + url.path
        var isHitHostOrPatternHost = false
        if let hostList = domainControl.hostList {
            for hostItemInList in hostList {
                if hostPath.hasPrefix(hostItemInList) {
                    isHitHostOrPatternHost = true
                    break
                }
            }
        }
        if !isHitHostOrPatternHost, let patternList = domainControl.patternList {
            for pattern in patternList {
                if let match = try? NSRegularExpression(pattern: pattern) {
                    let matchesArray = match.matches(hostPath)
                    if !matchesArray.isEmpty {
                        isHitHostOrPatternHost = true
                    }
                }
            }
        }
        if domainControl.type == Self.TYPE_ALLOW {
            return isHitHostOrPatternHost
        } else if domainControl.type == Self.TYPE_DENY {
            return !isHitHostOrPatternHost
        }
        return Self.DEFAULT_RESULT
    }
}
