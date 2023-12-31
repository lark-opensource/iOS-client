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
"Common_G_FromView_CancelButton":{
"hash":"G6E",
"#vars":0
},
"Common_G_FromView_ConfirmButton":{
"hash":"weE",
"#vars":0
},
"Common_G_FromView_CopyLink":{
"hash":"h9Q",
"#vars":0
},
"Common_G_FromView_LinkCopied":{
"hash":"37M",
"#vars":0
},
"Common_G_FromView_OperationFailedCodePercentAt":{
"hash":"SQE",
"#vars":0
},
"Common_G_FromView_Refresh":{
"hash":"M48",
"#vars":0
},
"Common_G_FromView_ShareToChat":{
"hash":"FWc",
"#vars":0
},
"Common_G_Player_Live_Label":{
"hash":"w0U",
"#vars":0
},
"Common_M_ImageErrorTryAgainLater_Toast":{
"hash":"VyE",
"#vars":0
}
},
"name":"LarkLive",
"short_key":true,
"config":{
"positional-args":true,
"use-native":true,
"mapping":{
"ms":"ms-MY",
"id":"id-ID",
"de":"de-DE",
"en":"en-US",
"es":"es-ES",
"fr":"fr-FR",
"it":"it-IT",
"pt":"pt-BR",
"vi":"vi-VN",
"ru":"ru-RU",
"hi":"hi-IN",
"th":"th-TH",
"ko":"ko-KR",
"zh":"zh-CN",
"ja":"ja-JP"
}
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkLiveAutoBundle, moduleName: "LarkLive", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkLiveAutoBundle, moduleName: "LarkLive", lang: lang) ?? key
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
    final class LarkLive {
        @inlinable
        static var Common_G_FromView_CancelButton: String {
            return LocalizedString(key: "G6E", originalKey: "Common_G_FromView_CancelButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_CancelButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "G6E", originalKey: "Common_G_FromView_CancelButton", lang: __lang)
        }
        @inlinable
        static var Common_G_FromView_ConfirmButton: String {
            return LocalizedString(key: "weE", originalKey: "Common_G_FromView_ConfirmButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_ConfirmButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "weE", originalKey: "Common_G_FromView_ConfirmButton", lang: __lang)
        }
        @inlinable
        static var Common_G_FromView_CopyLink: String {
            return LocalizedString(key: "h9Q", originalKey: "Common_G_FromView_CopyLink")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_CopyLink(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "h9Q", originalKey: "Common_G_FromView_CopyLink", lang: __lang)
        }
        @inlinable
        static var Common_G_FromView_LinkCopied: String {
            return LocalizedString(key: "37M", originalKey: "Common_G_FromView_LinkCopied")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_LinkCopied(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "37M", originalKey: "Common_G_FromView_LinkCopied", lang: __lang)
        }
        @inlinable
        static var Common_G_FromView_OperationFailedCodePercentAt: String {
            return LocalizedString(key: "SQE", originalKey: "Common_G_FromView_OperationFailedCodePercentAt")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_OperationFailedCodePercentAt(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "SQE", originalKey: "Common_G_FromView_OperationFailedCodePercentAt", lang: __lang)
        }
        @inlinable
        static var Common_G_FromView_Refresh: String {
            return LocalizedString(key: "M48", originalKey: "Common_G_FromView_Refresh")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_Refresh(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "M48", originalKey: "Common_G_FromView_Refresh", lang: __lang)
        }
        @inlinable
        static var Common_G_FromView_ShareToChat: String {
            return LocalizedString(key: "FWc", originalKey: "Common_G_FromView_ShareToChat")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_FromView_ShareToChat(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "FWc", originalKey: "Common_G_FromView_ShareToChat", lang: __lang)
        }
        @inlinable
        static var Common_G_Player_Live_Label: String {
            return LocalizedString(key: "w0U", originalKey: "Common_G_Player_Live_Label")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_G_Player_Live_Label(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "w0U", originalKey: "Common_G_Player_Live_Label", lang: __lang)
        }
        @inlinable
        static var Common_M_ImageErrorTryAgainLater_Toast: String {
            return LocalizedString(key: "VyE", originalKey: "Common_M_ImageErrorTryAgainLater_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Common_M_ImageErrorTryAgainLater_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "VyE", originalKey: "Common_M_ImageErrorTryAgainLater_Toast", lang: __lang)
        }
    }
}
// swiftlint:enable all
