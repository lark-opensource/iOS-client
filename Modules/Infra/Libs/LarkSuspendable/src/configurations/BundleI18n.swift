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
"Lark_Core_AddToMore_Foating_Text":{
"hash":"moc",
"#vars":0
},
"Lark_Core_Added_Foating_Text":{
"hash":"l2Q",
"#vars":0
},
"Lark_Core_CancelFloating":{
"hash":"UNo",
"#vars":0
},
"Lark_Core_FloatedSuccessfully":{
"hash":"q/0",
"#vars":0
},
"Lark_Core_FloatingLimit":{
"hash":"h90",
"#vars":0
},
"Lark_Core_FloatingLimitDesc":{
"hash":"s+s",
"#vars":0
},
"Lark_Core_FloatingLimitDescOK":{
"hash":"Qns",
"#vars":0
},
"Lark_Core_FloatingWindow":{
"hash":"458",
"#vars":0
},
"Lark_Core_MovedAgain":{
"hash":"LVQ",
"#vars":0
},
"Lark_Core_PutIntoFloating":{
"hash":"6DI",
"#vars":0
},
"Lark_Floating_Apps":{
"hash":"Wnc",
"#vars":0
},
"Lark_Floating_Chats":{
"hash":"lnY",
"#vars":0
},
"Lark_Floating_Clear":{
"hash":"N/k",
"#vars":0
},
"Lark_Floating_ConfirmClear":{
"hash":"6c4",
"#vars":0
},
"Lark_Floating_Docs":{
"hash":"YEs",
"#vars":0
},
"Lark_Floating_FloatingTitle":{
"hash":"Yk8",
"#vars":0
},
"Lark_Floating_Links":{
"hash":"WBs",
"#vars":0
},
"Lark_Floating_Moments":{
"hash":"p6s",
"#vars":0
},
"Lark_Floating_Other":{
"hash":"lXw",
"#vars":0
},
"Lark_Floating_Topics":{
"hash":"Hng",
"#vars":0
}
},
"name":"LarkSuspendable",
"short_key":true,
"config":{
"positional-args":true,
"use-native":true,
"public":true
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

public final class BundleI18n: LanguageManager {
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkSuspendableAutoBundle, moduleName: "LarkSuspendable", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkSuspendableAutoBundle, moduleName: "LarkSuspendable", lang: lang) ?? key
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
    public final class LarkSuspendable {
        @inlinable
        public static var Lark_Core_AddToMore_Foating_Text: String {
            return LocalizedString(key: "moc", originalKey: "Lark_Core_AddToMore_Foating_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_AddToMore_Foating_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "moc", originalKey: "Lark_Core_AddToMore_Foating_Text", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_Added_Foating_Text: String {
            return LocalizedString(key: "l2Q", originalKey: "Lark_Core_Added_Foating_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_Added_Foating_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "l2Q", originalKey: "Lark_Core_Added_Foating_Text", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_CancelFloating: String {
            return LocalizedString(key: "UNo", originalKey: "Lark_Core_CancelFloating")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_CancelFloating(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "UNo", originalKey: "Lark_Core_CancelFloating", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_FloatedSuccessfully: String {
            return LocalizedString(key: "q/0", originalKey: "Lark_Core_FloatedSuccessfully")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_FloatedSuccessfully(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "q/0", originalKey: "Lark_Core_FloatedSuccessfully", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_FloatingLimit: String {
            return LocalizedString(key: "h90", originalKey: "Lark_Core_FloatingLimit")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_FloatingLimit(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "h90", originalKey: "Lark_Core_FloatingLimit", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_FloatingLimitDesc: String {
            return LocalizedString(key: "s+s", originalKey: "Lark_Core_FloatingLimitDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_FloatingLimitDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "s+s", originalKey: "Lark_Core_FloatingLimitDesc", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_FloatingLimitDescOK: String {
            return LocalizedString(key: "Qns", originalKey: "Lark_Core_FloatingLimitDescOK")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_FloatingLimitDescOK(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Qns", originalKey: "Lark_Core_FloatingLimitDescOK", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_FloatingWindow: String {
            return LocalizedString(key: "458", originalKey: "Lark_Core_FloatingWindow")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_FloatingWindow(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "458", originalKey: "Lark_Core_FloatingWindow", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_MovedAgain: String {
            return LocalizedString(key: "LVQ", originalKey: "Lark_Core_MovedAgain")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_MovedAgain(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "LVQ", originalKey: "Lark_Core_MovedAgain", lang: __lang)
        }
        @inlinable
        public static var Lark_Core_PutIntoFloating: String {
            return LocalizedString(key: "6DI", originalKey: "Lark_Core_PutIntoFloating")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Core_PutIntoFloating(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6DI", originalKey: "Lark_Core_PutIntoFloating", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Apps: String {
            return LocalizedString(key: "Wnc", originalKey: "Lark_Floating_Apps")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Apps(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Wnc", originalKey: "Lark_Floating_Apps", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Chats: String {
            return LocalizedString(key: "lnY", originalKey: "Lark_Floating_Chats")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Chats(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lnY", originalKey: "Lark_Floating_Chats", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Clear: String {
            return LocalizedString(key: "N/k", originalKey: "Lark_Floating_Clear")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Clear(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "N/k", originalKey: "Lark_Floating_Clear", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_ConfirmClear: String {
            return LocalizedString(key: "6c4", originalKey: "Lark_Floating_ConfirmClear")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_ConfirmClear(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6c4", originalKey: "Lark_Floating_ConfirmClear", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Docs: String {
            return LocalizedString(key: "YEs", originalKey: "Lark_Floating_Docs")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Docs(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YEs", originalKey: "Lark_Floating_Docs", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_FloatingTitle: String {
            return LocalizedString(key: "Yk8", originalKey: "Lark_Floating_FloatingTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_FloatingTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Yk8", originalKey: "Lark_Floating_FloatingTitle", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Links: String {
            return LocalizedString(key: "WBs", originalKey: "Lark_Floating_Links")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Links(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "WBs", originalKey: "Lark_Floating_Links", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Moments: String {
            return LocalizedString(key: "p6s", originalKey: "Lark_Floating_Moments")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Moments(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "p6s", originalKey: "Lark_Floating_Moments", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Other: String {
            return LocalizedString(key: "lXw", originalKey: "Lark_Floating_Other")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Other(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lXw", originalKey: "Lark_Floating_Other", lang: __lang)
        }
        @inlinable
        public static var Lark_Floating_Topics: String {
            return LocalizedString(key: "Hng", originalKey: "Lark_Floating_Topics")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Floating_Topics(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Hng", originalKey: "Lark_Floating_Topics", lang: __lang)
        }
    }
}
// swiftlint:enable all
