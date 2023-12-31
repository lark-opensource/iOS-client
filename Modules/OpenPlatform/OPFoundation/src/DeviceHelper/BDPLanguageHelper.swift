//
//  BDPLanguageHelper.swift
//  Timor
//
//  Created by houjihu on 2020/4/25.
//

import Foundation
import LarkLocalizations

@objcMembers
public final class BDPLanguageHelper: NSObject {
    /// app语言，zh_CN
    public static func appLanguage() -> String {
        return LanguageManager.currentLanguage.localeIdentifier
    }

    /// strings国际化字符串名称，zh-CN
    public static func stringsLanguage() -> String {
        return LanguageManager.currentLanguage.languageIdentifier
    }

    /// current locale
    public static func currentLocale() -> Locale {
        return LanguageManager.locale
    }

    /// 收敛语言获取实现到基础库
    public static func getLocale(with key: String, in bundle: Bundle, moduleName: String) -> String? {
        /// 旧生成代码依赖新的LarkLocalization. 如果在旧的release分支上用新的eesc生成代码，不加条件编译，会因为没有新的LarkLocalization的方法而导致编译失败
        #if USE_BASE_IMP
        return LanguageManager.localizedString(key: key, bundle: bundle, moduleName: moduleName)
        #else
        return nil
        #endif
    }
}
