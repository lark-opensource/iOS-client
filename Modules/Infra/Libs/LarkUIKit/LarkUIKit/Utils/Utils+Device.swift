//
//  Utils+Device.swift
//  LarkFoundation
//
//  Created by K3 on 2018/6/12.
//  Copyright © 2018 com.bytedance.lark. All rights reserved.
//

import Foundation
import LarkFoundation
import LarkLocalizations
import UIKit
import LarkReleaseConfig

public var userAgentName = "Lark"

public extension Utils {
    static func getVersions() -> (String, String, String) {
        let appVersionStr = appVersion.lf.matchingStrings(regex: "\\d+\\.\\d+\\.\\d+").first?.first ?? "1.0.0"
        let version = UIDevice.current.systemVersion
        let versionStr = version.replacingOccurrences(of: ".", with: "_")
        return (appVersionStr, version, versionStr)
    }

    static var additionalUAString = ""

    static var userAgent: String {
        let (appVersionStr, version, versionStr) = getVersions()
        var name: String
        if ReleaseConfig.isFeishu {
            name = "Feishu"
        } else {
            name = "Lark"
        }
        if Display.pad {
            return "Mozilla/5.0 "
                + "(iPad; CPU iPhone OS \(versionStr) like Mac OS X) "
                + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(version) "
                + "Mobile/15E148 Safari/604.1 \(userAgentName)/\(appVersionStr) LarkLocale/\(LanguageManager.currentLanguage.localeIdentifier) ChannelName/\(name)"
                + additionalUAString
        } else {
            return "Mozilla/5.0 "
                + "(iPhone; CPU iPhone OS \(versionStr) like Mac OS X) "
                + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(version) "
                + "Mobile/15E148 Safari/604.1 \(userAgentName)/\(appVersionStr) LarkLocale/\(LanguageManager.currentLanguage.localeIdentifier) ChannelName/\(name)"
                + additionalUAString
        }
    }

    // 拨打电话
    class func telecall(phoneNumber: String) {
        let phoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        let callStr = "telprompt://\(phoneNumber)"
        guard let url = URL(string: callStr) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
