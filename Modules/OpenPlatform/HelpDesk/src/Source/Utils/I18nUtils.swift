//
//  BannerModel.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/26.
//

import Foundation
import LarkLocalizations

class I18nUtils {
    
    /// 获取国际化字段值
    /// - Parameters:
    ///   - i18n: 国际化字段
    ///   - default: 默认字段值
    static func getLocal(i18n: [String: String]) -> String {
        // 获取本地语言
        let localLanguage = LanguageManager.currentLanguage.rawValue
        // 获取本地语言对应的内容
        let localContent = getLocal(i18n: i18n, localLanguage: localLanguage, defaultContent: "")
        if !localContent.isEmpty {
            // 不为空直接返回
            return localContent
        } else {
            // 未找到对应语言，则默认使用 en-US
            return getLocal(i18n: i18n, localLanguage: "en_US", defaultContent: "")
        }
    }
    
    // 查找指定语言的内容
    private static func getLocal(i18n: [String: String], localLanguage: String, defaultContent: String) -> String {
        /// localLanguage 统一转为小写后再比较
        let localLanguage = localLanguage.lowercased()
        
        let localContent = i18n.first { (key: String, value: String) in
            // key 统一转为小写后再比较
            key.lowercased() == localLanguage
        }?.value
        
        if let localContent = localContent, !localContent.isEmpty {
            return localContent
        } else {
            return defaultContent
        }
    }
    
}
