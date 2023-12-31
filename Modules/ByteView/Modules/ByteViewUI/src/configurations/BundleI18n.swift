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
"View_G_CouldNotLoadTryReloading":{
"hash":"LsE",
"#vars":0
},
"View_G_GotItButton":{
"hash":"/gM",
"#vars":0
},
"View_G_NextOne":{
"hash":"b1Y",
"#vars":0
},
"View_G_SkipButton":{
"hash":"yhg",
"#vars":0
},
"View_VM_Loading":{
"hash":"1+M",
"#vars":0
}
},
"name":"ByteViewUI",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.ByteViewUIAutoBundle, moduleName: "ByteViewUI", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.ByteViewUIAutoBundle, moduleName: "ByteViewUI", lang: lang) ?? key
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
    final class ByteViewUI {
        @inlinable
        static var View_G_CouldNotLoadTryReloading: String {
            return LocalizedString(key: "LsE", originalKey: "View_G_CouldNotLoadTryReloading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_CouldNotLoadTryReloading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "LsE", originalKey: "View_G_CouldNotLoadTryReloading", lang: __lang)
        }
        @inlinable
        static var View_G_GotItButton: String {
            return LocalizedString(key: "/gM", originalKey: "View_G_GotItButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_GotItButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/gM", originalKey: "View_G_GotItButton", lang: __lang)
        }
        @inlinable
        static var View_G_NextOne: String {
            return LocalizedString(key: "b1Y", originalKey: "View_G_NextOne")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_NextOne(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "b1Y", originalKey: "View_G_NextOne", lang: __lang)
        }
        @inlinable
        static var View_G_SkipButton: String {
            return LocalizedString(key: "yhg", originalKey: "View_G_SkipButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_SkipButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yhg", originalKey: "View_G_SkipButton", lang: __lang)
        }
        @inlinable
        static var View_VM_Loading: String {
            return LocalizedString(key: "1+M", originalKey: "View_VM_Loading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_VM_Loading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "1+M", originalKey: "View_VM_Loading", lang: __lang)
        }
    }
}
// swiftlint:enable all
