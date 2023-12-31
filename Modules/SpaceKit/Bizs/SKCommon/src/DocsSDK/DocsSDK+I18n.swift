//
//  SpaceKit+I18n.swift
//  SpaceKit
//
//  Modified by Duan Xiaochen on 2019/8/14.
//

import Foundation
import LarkLocalizations
import SKResource

extension DocsSDK {
    public static var systemLanguage: String? {
        return Locale.preferredLanguages.first
    }

    // 改成实时直接获取，避免语言环境改变，读取不到最新语言环境的问题
    public static var currentLanguage: Lang {
        return I18n.currentLanguage()
    }
    
    //doc封装转换的language 用于向后台传递（lark会给到zh-CN，但是后台识别的zh）
    public static var convertedLanguage: String {
        return currentLanguage.languageCode ?? "en"
    }
    
    public static var convertedDefaultLanguageEn: String {
        return "en"
    }

    public static var currentLocale: Locale {
        return I18n.currentLocale()
    }
}
