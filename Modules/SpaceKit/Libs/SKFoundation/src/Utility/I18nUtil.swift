//
//  I18nUtil.swift
//  SpaceKit
//
//  Created by maxiao on 2020/4/8.
//

// Copy from bitable
import Foundation
import LarkStorage

public final class I18nUtil {

    // swiftlint:disable identifier_name
    public struct LanguageType {
        public static let zh_CN = "zh-CN"
        public static let en_US = "en-US"
    }
     

    //这里是从LarkLocalizations 那边 UserDefaults拿的，改统一存储的时候需要注意是否拿得到，最好不要写成这种硬编码
    public class var appleLanguage: [String] {
        return KVPublic.Common.appleLanguages.value()
    }
    public class var systemLanguage: String {
        return KVPublic.Common.appleLocale.value() ?? ""
    }

    public static var currentLanguage: String {
        var current = systemLanguage
        if let language = appleLanguage.first, !language.isEmpty {
            current = language
        }

        if current.hasPrefix("en") {
            return LanguageType.en_US
        } else if current.hasPrefix("zh") {
            return LanguageType.zh_CN
        } else {
            return LanguageType.en_US
        }
    }
}
