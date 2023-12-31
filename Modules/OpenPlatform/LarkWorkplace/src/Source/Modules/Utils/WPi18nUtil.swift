//
//  WPi18nUtil.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/4/14.
//

import Foundation

enum WPi18nUtil {
    /// Get text for current locale
    /// Priority: current locale > default locale > en_us > zh_cn > ja_jp > empty text
    ///
    /// - Parameters:
    ///   - textCollection: A dictionary contains text for multi-locale
    ///   - defaultLocale: default locale
    static func getI18nText(_ textCollection: [String: String], defaultLocale: String?) -> String? {
        /// 语言选择策略：当前语言环境 -> 配置的默认语言 -> 英 -> 中 -> 日 ->只有一个的case有哪个选哪个
        let locale = WorkplaceTool.curLanguage()
        if let defaultLocale = defaultLocale {
            /// 语言策略：当前语言环境 -> 配置的默认语言 -> 英 -> 中 -> 日
            return  textCollection[locale] ?? textCollection[defaultLocale] ?? textCollection["en_us"] ?? textCollection["zh_cn"] ?? textCollection["ja_jp"]
        } else {
            /// 老版本编辑器如果只有一种语言就没有 defaultLocale
            /// 这种情况下如果前面的策略不匹配，就用唯一配置的这个语言
            return  textCollection[locale] ?? textCollection["en_us"] ?? textCollection["zh_cn"] ?? textCollection["ja_jp"]  ?? textCollection.first?.value
        }
    }
}
