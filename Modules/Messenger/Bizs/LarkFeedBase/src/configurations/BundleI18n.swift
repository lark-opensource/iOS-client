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
"Lark_Core_TouchAndHold_MuteChats_Button":{
"hash":"Co8",
"#vars":0
},
"Lark_Core_TouchAndHold_MuteChats_MutedToast":{
"hash":"RIs",
"#vars":0
},
"Lark_Core_TouchAndHold_UnmuteChats_Button":{
"hash":"fkU",
"#vars":0
},
"Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast":{
"hash":"LxU",
"#vars":0
},
"Lark_Core_UnableToMuteNotificationsTryLater_Toast":{
"hash":"WH4",
"#vars":0
},
"Lark_Core_UnableToUnmuteNotificationsTryLater_Toast":{
"hash":"kts",
"#vars":0
},
"Lark_Event_EventInProgress_Status":{
"hash":"q6w",
"#vars":0
},
"Lark_Event_NumMinLater_Text":{
"hash":"9Ds",
"#vars":1,
"normal_vars":["number"]
},
"Lark_Legacy_UnReadCount":{
"hash":"eFo",
"#vars":1,
"normal_vars":["unread_count"]
},
"Lark_Legacy_UnReadCounts":{
"hash":"3rk",
"#vars":1,
"normal_vars":["unread_count"]
}
},
"name":"LarkFeedBase",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkFeedBaseAutoBundle, moduleName: "LarkFeedBase", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkFeedBaseAutoBundle, moduleName: "LarkFeedBase", lang: lang) ?? key
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
    final class LarkFeedBase {
        @inlinable
        static var Lark_Core_TouchAndHold_MuteChats_Button: String {
            return LocalizedString(key: "Co8", originalKey: "Lark_Core_TouchAndHold_MuteChats_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TouchAndHold_MuteChats_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Co8", originalKey: "Lark_Core_TouchAndHold_MuteChats_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_TouchAndHold_MuteChats_MutedToast: String {
            return LocalizedString(key: "RIs", originalKey: "Lark_Core_TouchAndHold_MuteChats_MutedToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TouchAndHold_MuteChats_MutedToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "RIs", originalKey: "Lark_Core_TouchAndHold_MuteChats_MutedToast", lang: __lang)
        }
        @inlinable
        static var Lark_Core_TouchAndHold_UnmuteChats_Button: String {
            return LocalizedString(key: "fkU", originalKey: "Lark_Core_TouchAndHold_UnmuteChats_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TouchAndHold_UnmuteChats_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "fkU", originalKey: "Lark_Core_TouchAndHold_UnmuteChats_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast: String {
            return LocalizedString(key: "LxU", originalKey: "Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "LxU", originalKey: "Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast", lang: __lang)
        }
        @inlinable
        static var Lark_Core_UnableToMuteNotificationsTryLater_Toast: String {
            return LocalizedString(key: "WH4", originalKey: "Lark_Core_UnableToMuteNotificationsTryLater_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_UnableToMuteNotificationsTryLater_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "WH4", originalKey: "Lark_Core_UnableToMuteNotificationsTryLater_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_Core_UnableToUnmuteNotificationsTryLater_Toast: String {
            return LocalizedString(key: "kts", originalKey: "Lark_Core_UnableToUnmuteNotificationsTryLater_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_UnableToUnmuteNotificationsTryLater_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "kts", originalKey: "Lark_Core_UnableToUnmuteNotificationsTryLater_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_Event_EventInProgress_Status: String {
            return LocalizedString(key: "q6w", originalKey: "Lark_Event_EventInProgress_Status")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Event_EventInProgress_Status(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "q6w", originalKey: "Lark_Event_EventInProgress_Status", lang: __lang)
        }
        @inlinable
        static var __Lark_Event_NumMinLater_Text: String {
            return LocalizedString(key: "9Ds", originalKey: "Lark_Event_NumMinLater_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Event_NumMinLater_Text(_ number: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Event_NumMinLater_Text(number: `number`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Event_NumMinLater_Text(number: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "9Ds", originalKey: "Lark_Event_NumMinLater_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{number}}", with: "\(`number`)")
            return template
        }
        @inlinable
        static var __Lark_Legacy_UnReadCount: String {
            return LocalizedString(key: "eFo", originalKey: "Lark_Legacy_UnReadCount")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_UnReadCount(_ unread_count: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_UnReadCount(unread_count: `unread_count`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_UnReadCount(unread_count: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "eFo", originalKey: "Lark_Legacy_UnReadCount", lang: __lang)
            template = template.replacingOccurrences(of: "{{unread_count}}", with: "\(`unread_count`)")
            return template
        }
        @inlinable
        static var __Lark_Legacy_UnReadCounts: String {
            return LocalizedString(key: "3rk", originalKey: "Lark_Legacy_UnReadCounts")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_UnReadCounts(_ unread_count: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_UnReadCounts(unread_count: `unread_count`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_UnReadCounts(unread_count: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "3rk", originalKey: "Lark_Legacy_UnReadCounts", lang: __lang)
            template = template.replacingOccurrences(of: "{{unread_count}}", with: "\(`unread_count`)")
            return template
        }
    }
}
// swiftlint:enable all
