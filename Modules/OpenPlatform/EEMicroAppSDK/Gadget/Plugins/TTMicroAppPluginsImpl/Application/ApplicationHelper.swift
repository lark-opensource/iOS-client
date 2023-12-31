//
//  ApplicationHelper.swift
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/7/5.
//

import Foundation

@objcMembers
public final class ApplicationHelper: NSObject {
    /// app语言，zh_CN
    public static func appLanguage() -> String {
        return BDPLanguageHelper.appLanguage()
    }

    /// strings国际化字符串名称，zh-CN
    public static func stringsLanguage() -> String {
        return BDPLanguageHelper.stringsLanguage()
    }

    /// current locale
    public static func currentLocale() -> Locale {
        return BDPLanguageHelper.currentLocale()
    }

    /// app版本
    public static func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// BundleID
    public static func bundleIdentifier() -> String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    /// buildVersion
    public static func buildVersion() -> String {
        if var text = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return text.replacingOccurrences(of: ".", with: "")
        }
        return ""
    }

    public static func appDisplayname() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }
        if let name: String = dictionary["CFBundleName"] as? String {
            return name
        } else {
            return ""
        }
    }
}
