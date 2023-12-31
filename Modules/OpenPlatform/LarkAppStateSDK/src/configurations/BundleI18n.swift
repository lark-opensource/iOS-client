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
"AppDetail_Application_Mechanism_AppDeactivatedWord":{
"hash":"XlQ",
"#vars":1,
"normal_vars":["user_name"]
},
"AppDetail_Application_Mechanism_NoAccessBtn":{
"hash":"I8k",
"#vars":0
},
"AppDetail_Application_Mechanism_NoAccessWords":{
"hash":"TbY",
"#vars":0
},
"Lark_OpenPlatform_NetworkErrMsg":{
"hash":"vJg",
"#vars":0
},
"OpenPlatform_AppCenter_AppDeletedDesc":{
"hash":"0Ns",
"#vars":1,
"normal_vars":["user_name"]
},
"OpenPlatform_AppCenter_AppOfflineDesc":{
"hash":"i0E",
"#vars":0
},
"OpenPlatform_AppCenter_AppOfflineLarkDesc":{
"hash":"lqE",
"#vars":0
}
},
"name":"LarkAppStateSDK",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkAppStateSDKAutoBundle, moduleName: "LarkAppStateSDK", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkAppStateSDKAutoBundle, moduleName: "LarkAppStateSDK", lang: lang) ?? key
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
    final class LarkAppStateSDK {
        @inlinable
        static var __AppDetail_Application_Mechanism_AppDeactivatedWord: String {
            return LocalizedString(key: "XlQ", originalKey: "AppDetail_Application_Mechanism_AppDeactivatedWord")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func AppDetail_Application_Mechanism_AppDeactivatedWord(_ user_name: Any, lang __lang: Lang? = nil) -> String {
          return AppDetail_Application_Mechanism_AppDeactivatedWord(user_name: `user_name`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func AppDetail_Application_Mechanism_AppDeactivatedWord(user_name: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "XlQ", originalKey: "AppDetail_Application_Mechanism_AppDeactivatedWord", lang: __lang)
            template = template.replacingOccurrences(of: "{{user_name}}", with: "\(`user_name`)")
            return template
        }
        @inlinable
        static var AppDetail_Application_Mechanism_NoAccessBtn: String {
            return LocalizedString(key: "I8k", originalKey: "AppDetail_Application_Mechanism_NoAccessBtn")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func AppDetail_Application_Mechanism_NoAccessBtn(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "I8k", originalKey: "AppDetail_Application_Mechanism_NoAccessBtn", lang: __lang)
        }
        @inlinable
        static var AppDetail_Application_Mechanism_NoAccessWords: String {
            return LocalizedString(key: "TbY", originalKey: "AppDetail_Application_Mechanism_NoAccessWords")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func AppDetail_Application_Mechanism_NoAccessWords(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "TbY", originalKey: "AppDetail_Application_Mechanism_NoAccessWords", lang: __lang)
        }
        @inlinable
        static var Lark_OpenPlatform_NetworkErrMsg: String {
            return LocalizedString(key: "vJg", originalKey: "Lark_OpenPlatform_NetworkErrMsg")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_OpenPlatform_NetworkErrMsg(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vJg", originalKey: "Lark_OpenPlatform_NetworkErrMsg", lang: __lang)
        }
        @inlinable
        static var __OpenPlatform_AppCenter_AppDeletedDesc: String {
            return LocalizedString(key: "0Ns", originalKey: "OpenPlatform_AppCenter_AppDeletedDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_AppDeletedDesc(_ user_name: Any, lang __lang: Lang? = nil) -> String {
          return OpenPlatform_AppCenter_AppDeletedDesc(user_name: `user_name`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_AppCenter_AppDeletedDesc(user_name: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "0Ns", originalKey: "OpenPlatform_AppCenter_AppDeletedDesc", lang: __lang)
            template = template.replacingOccurrences(of: "{{user_name}}", with: "\(`user_name`)")
            return template
        }
        @inlinable
        static var OpenPlatform_AppCenter_AppOfflineDesc: String {
            return LocalizedString(key: "i0E", originalKey: "OpenPlatform_AppCenter_AppOfflineDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_AppOfflineDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "i0E", originalKey: "OpenPlatform_AppCenter_AppOfflineDesc", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_AppOfflineLarkDesc: String {
            return LocalizedString(key: "lqE", originalKey: "OpenPlatform_AppCenter_AppOfflineLarkDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_AppOfflineLarkDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lqE", originalKey: "OpenPlatform_AppCenter_AppOfflineLarkDesc", lang: __lang)
        }
    }
}
// swiftlint:enable all
