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
"Lark_Legacy_SendDocKey":{
"hash":"BfA",
"#vars":0
},
"Lark_Legacy_Vote":{
"hash":"pZI",
"#vars":0
},
"Lark_Project_Projects":{
"hash":"mgU",
"#vars":0
},
"Lark_Legacy_SideEvent":{
"hash":"dd4",
"#vars":0
},
"Todo_IM_TextFieldAddTask_Button":{
"hash":"JKo",
"#vars":0
},
"Lark_Core_TimeZoneChanged_Desc":{
"hash":"ZeQ",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_TimeZoneChanged_Later_Button":{
"hash":"zwg",
"#vars":0
},
"Lark_Core_TimeZoneChanged_Restart_Button":{
"hash":"p3k",
"#vars":0
},
"Lark_Core_TimeZoneChanged_Title":{
"hash":"wtM",
"#vars":0
},
"Bitable_Runninglist_Name":{
"hash":"sOc",
"#vars":0
}
},
"name":"MessengerMod",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.MessengerModAutoBundle, moduleName: "MessengerMod", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.MessengerModAutoBundle, moduleName: "MessengerMod", lang: lang) ?? key
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
    final class LarkChat {
        @inlinable
        static var Lark_Legacy_SendDocKey: String {
            return LocalizedString(key: "BfA", originalKey: "Lark_Legacy_SendDocKey")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SendDocKey(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "BfA", originalKey: "Lark_Legacy_SendDocKey", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Vote: String {
            return LocalizedString(key: "pZI", originalKey: "Lark_Legacy_Vote")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Vote(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "pZI", originalKey: "Lark_Legacy_Vote", lang: __lang)
        }
        @inlinable
        static var Lark_Project_Projects: String {
            return LocalizedString(key: "mgU", originalKey: "Lark_Project_Projects")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Project_Projects(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "mgU", originalKey: "Lark_Project_Projects", lang: __lang)
        }
    }
    final class Calendar {
        @inlinable
        static var Lark_Legacy_SideEvent: String {
            return LocalizedString(key: "dd4", originalKey: "Lark_Legacy_SideEvent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SideEvent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "dd4", originalKey: "Lark_Legacy_SideEvent", lang: __lang)
        }
    }
    final class Todo {
        @inlinable
        static var Todo_IM_TextFieldAddTask_Button: String {
            return LocalizedString(key: "JKo", originalKey: "Todo_IM_TextFieldAddTask_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Todo_IM_TextFieldAddTask_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "JKo", originalKey: "Todo_IM_TextFieldAddTask_Button", lang: __lang)
        }
    }
    final class LarkCore {
        @inlinable
        static var __Lark_Core_TimeZoneChanged_Desc: String {
            return LocalizedString(key: "ZeQ", originalKey: "Lark_Core_TimeZoneChanged_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_TimeZoneChanged_Desc(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "ZeQ", originalKey: "Lark_Core_TimeZoneChanged_Desc", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_Core_TimeZoneChanged_Later_Button: String {
            return LocalizedString(key: "zwg", originalKey: "Lark_Core_TimeZoneChanged_Later_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TimeZoneChanged_Later_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zwg", originalKey: "Lark_Core_TimeZoneChanged_Later_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_TimeZoneChanged_Restart_Button: String {
            return LocalizedString(key: "p3k", originalKey: "Lark_Core_TimeZoneChanged_Restart_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TimeZoneChanged_Restart_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "p3k", originalKey: "Lark_Core_TimeZoneChanged_Restart_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_TimeZoneChanged_Title: String {
            return LocalizedString(key: "wtM", originalKey: "Lark_Core_TimeZoneChanged_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_TimeZoneChanged_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "wtM", originalKey: "Lark_Core_TimeZoneChanged_Title", lang: __lang)
        }
    }
    final class CCM {
        @inlinable
        static var Bitable_Runninglist_Name: String {
            return LocalizedString(key: "sOc", originalKey: "Bitable_Runninglist_Name")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Bitable_Runninglist_Name(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "sOc", originalKey: "Bitable_Runninglist_Name", lang: __lang)
        }
    }
}
// swiftlint:enable all
