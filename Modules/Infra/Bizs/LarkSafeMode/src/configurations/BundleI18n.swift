// swiftlint:disable all
/**
Warning: Do Not Edit It!
Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
Toolchains For EE


______ ______ _____        __
|  ____|  ____|_   _|      / _|
| |__  | |__    | |  _ __ | |_ _ __ __ _
|  __| |  __|   | | | '_ \|  _| '__/ _` |
| |____| |____ _| |_| | | | | | | | (_| |
|______|______|_____|_| |_|_| |_|  \__,_|


Meta信息不要删除！如果冲突，重新生成BundleI18n就好
---Meta---
{
"keys":{
"Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupportWithPhoneNumber_Text":{
"hash":"wPA",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupport_Text":{
"hash":"54U",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text":{
"hash":"VwY",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Login_SafeMode":{
"hash":"FqI",
"#vars":0
},
"Lark_Login_SafeModeCloseAppButton":{
"hash":"y1s",
"#vars":0
},
"Lark_Login_SafeModeDataError":{
"hash":"qUM",
"#vars":0
},
"Lark_Login_SafeModeDataErrorDesc":{
"hash":"UqQ",
"#vars":0
},
"Lark_Login_SafeModeDataFixing":{
"hash":"MyY",
"#vars":0
},
"Lark_Login_SafeModeDataFixingButton":{
"hash":"HXY",
"#vars":0
},
"Lark_Login_SafeModeFixFinished":{
"hash":"kuo",
"#vars":0
},
"Lark_Login_SafeModeFixFinishedDesc":{
"hash":"A/Q",
"#vars":0
},
"Lark_Login_SafeModeStartFixButton":{
"hash":"Lrg",
"#vars":0
}
},
"name":"LarkSafeMode",
"short_key":true,
"config":{
"positional-args":true,
"use-native":true
},
"fetch":{
"resources":[{
"projectId":2207,
"namespaceId":[34815,38483,34810]
},{
"projectId":2094,
"namespaceId":[34132,34137]
},{
"projectId":2085,
"namespaceId":[34083]
},{
"projectId":2103,
"namespaceId":[34186,34191,34187]
},{
"projectId":2108,
"namespaceId":[34221,34216]
},{
"projectId":2187,
"namespaceId":[34695]
},{
"projectId":2521,
"namespaceId":[38139]
},{
"projectId":3545,
"namespaceId":[37986]
},{
"projectId":4394,
"namespaceId":[41385]
},{
"projectId":8217,
"namespaceId":[50340,50342,50344],
"support_single_param":true
},{
"projectId":3788,
"namespaceId":[38915]
},{
"projectId":2095,
"namespaceId":[34143,34138]
},{
"projectId":3129,
"namespaceId":[37171]
},{
"projectId":2268,
"namespaceId":[35181],
"support_single_param":true
},{
"projectId":2176,
"namespaceId":[34629,41969,41970]
},{
"projectId":2085,
"namespaceId":[34078,34083]
},{
"projectId":2113,
"namespaceId":[34251,34246]
},{
"projectId":2086,
"namespaceId":[38121,34089]
},{
"projectId":2231,
"namespaceId":[34959]
},{
"projectId":8770,
"namespaceId":[52445,66909]
},{
"projectId":23858,
"namespaceId":[81561]
}],
"locale":["en-US","zh-CN","zh-TW","zh-HK","ja-JP","id-ID","de-DE","es-ES","fr-FR","it-IT","pt-BR","vi-VN","ru-RU","hi-IN","th-TH","ko-KR","ms-MY"]
}
}
---Meta---
*/

import Foundation
import LarkLocalizations

final class BundleI18n: LanguageManager {
    private static let _tableLock = NSLock()
    private static var _tableMap: [String: String] = {
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name("preferLanguageChangeNotification"),
            object: nil,
            queue: nil
        ) { (_) -> Void in
            _tableLock.lock(); defer { _tableLock.unlock() }
            BundleI18n._tableMap = [:]
        }
        return [:]
    }()
    @usableFromInline
    static func LocalizedString(key: String, originalKey: String, lang: Lang? = nil) -> String {
        func fetch() -> String {
            #if USE_DYNAMIC_RESOURCE
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkSafeModeAutoBundle, moduleName: "LarkSafeMode", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkSafeModeAutoBundle, moduleName: "LarkSafeMode", lang: lang) ?? key
            #endif
        }

        if lang != nil { return fetch() } // speicify lang will no cache, call api directly
        _tableLock.lock(); defer { _tableLock.unlock() }
        if let str = _tableMap[key] { return str }
        let str = fetch()
        _tableMap[key] = str
        return str
    }

    /*
     * you can set I18n like that:
     * static var done: String { @inline(__always) get { return LocalizedString(key: "done") } }
     */
    final class LarkSafeMode {
        @inlinable
        static var __Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupportWithPhoneNumber_Text: String {
            return LocalizedString(key: "wPA", originalKey: "Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupportWithPhoneNumber_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupportWithPhoneNumber_Text(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "wPA", originalKey: "Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupportWithPhoneNumber_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var __Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupport_Text: String {
            return LocalizedString(key: "54U", originalKey: "Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupport_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupport_Text(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "54U", originalKey: "Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupport_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var __Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text: String {
            return LocalizedString(key: "VwY", originalKey: "Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "VwY", originalKey: "Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_Login_SafeMode: String {
            return LocalizedString(key: "FqI", originalKey: "Lark_Login_SafeMode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeMode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "FqI", originalKey: "Lark_Login_SafeMode", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeCloseAppButton: String {
            return LocalizedString(key: "y1s", originalKey: "Lark_Login_SafeModeCloseAppButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeCloseAppButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "y1s", originalKey: "Lark_Login_SafeModeCloseAppButton", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeDataError: String {
            return LocalizedString(key: "qUM", originalKey: "Lark_Login_SafeModeDataError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeDataError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qUM", originalKey: "Lark_Login_SafeModeDataError", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeDataErrorDesc: String {
            return LocalizedString(key: "UqQ", originalKey: "Lark_Login_SafeModeDataErrorDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeDataErrorDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "UqQ", originalKey: "Lark_Login_SafeModeDataErrorDesc", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeDataFixing: String {
            return LocalizedString(key: "MyY", originalKey: "Lark_Login_SafeModeDataFixing")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeDataFixing(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "MyY", originalKey: "Lark_Login_SafeModeDataFixing", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeDataFixingButton: String {
            return LocalizedString(key: "HXY", originalKey: "Lark_Login_SafeModeDataFixingButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeDataFixingButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HXY", originalKey: "Lark_Login_SafeModeDataFixingButton", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeFixFinished: String {
            return LocalizedString(key: "kuo", originalKey: "Lark_Login_SafeModeFixFinished")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeFixFinished(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "kuo", originalKey: "Lark_Login_SafeModeFixFinished", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeFixFinishedDesc: String {
            return LocalizedString(key: "A/Q", originalKey: "Lark_Login_SafeModeFixFinishedDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeFixFinishedDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "A/Q", originalKey: "Lark_Login_SafeModeFixFinishedDesc", lang: __lang)
        }
        @inlinable
        static var Lark_Login_SafeModeStartFixButton: String {
            return LocalizedString(key: "Lrg", originalKey: "Lark_Login_SafeModeStartFixButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_SafeModeStartFixButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Lrg", originalKey: "Lark_Login_SafeModeStartFixButton", lang: __lang)
        }
    }
}
// swiftlint:enable all
