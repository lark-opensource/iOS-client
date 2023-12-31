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
"Lark_Legacy_ConfirmNow":{
"hash":"AtM",
"#vars":0
},
"Lark_Legacy_ImageSummarize":{
"hash":"7KI",
"#vars":0
},
"Lark_Legacy_MsgCard_AppUpdatePrompt":{
"hash":"nsA",
"#vars":0
},
"Lark_Legacy_MsgCard_CardPlaceholder":{
"hash":"4TU",
"#vars":0
},
"Lark_Legacy_MsgCard_DatePlusTimePlaceholder":{
"hash":"yBw",
"#vars":0
},
"Lark_Legacy_MsgCard_ImagePlaceholder":{
"hash":"C30",
"#vars":0
},
"Lark_Legacy_MsgCard_LongImgTag":{
"hash":"SP0",
"#vars":0
},
"Lark_Legacy_MsgCard_PickerPlaceholder":{
"hash":"4mk",
"#vars":0
},
"Lark_Legacy_MsgCard_SelectDatePlaceholder":{
"hash":"6kA",
"#vars":0
},
"Lark_Legacy_MsgCard_SelectTimePlaceholder":{
"hash":"d3o",
"#vars":0
},
"Lark_Settings_Cancel":{
"hash":"Tfc",
"#vars":0
}
},
"name":"NewLarkDynamic",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.NewLarkDynamicAutoBundle, moduleName: "NewLarkDynamic", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.NewLarkDynamicAutoBundle, moduleName: "NewLarkDynamic", lang: lang) ?? key
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
    public final class NewLarkDynamic {
        @inlinable
        public static var Lark_Legacy_ConfirmNow: String {
            return LocalizedString(key: "AtM", originalKey: "Lark_Legacy_ConfirmNow")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_ConfirmNow(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "AtM", originalKey: "Lark_Legacy_ConfirmNow", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_ImageSummarize: String {
            return LocalizedString(key: "7KI", originalKey: "Lark_Legacy_ImageSummarize")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_ImageSummarize(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7KI", originalKey: "Lark_Legacy_ImageSummarize", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_AppUpdatePrompt: String {
            return LocalizedString(key: "nsA", originalKey: "Lark_Legacy_MsgCard_AppUpdatePrompt")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_AppUpdatePrompt(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "nsA", originalKey: "Lark_Legacy_MsgCard_AppUpdatePrompt", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_CardPlaceholder: String {
            return LocalizedString(key: "4TU", originalKey: "Lark_Legacy_MsgCard_CardPlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_CardPlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4TU", originalKey: "Lark_Legacy_MsgCard_CardPlaceholder", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_DatePlusTimePlaceholder: String {
            return LocalizedString(key: "yBw", originalKey: "Lark_Legacy_MsgCard_DatePlusTimePlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_DatePlusTimePlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yBw", originalKey: "Lark_Legacy_MsgCard_DatePlusTimePlaceholder", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_ImagePlaceholder: String {
            return LocalizedString(key: "C30", originalKey: "Lark_Legacy_MsgCard_ImagePlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_ImagePlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "C30", originalKey: "Lark_Legacy_MsgCard_ImagePlaceholder", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_LongImgTag: String {
            return LocalizedString(key: "SP0", originalKey: "Lark_Legacy_MsgCard_LongImgTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_LongImgTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "SP0", originalKey: "Lark_Legacy_MsgCard_LongImgTag", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_PickerPlaceholder: String {
            return LocalizedString(key: "4mk", originalKey: "Lark_Legacy_MsgCard_PickerPlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_PickerPlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4mk", originalKey: "Lark_Legacy_MsgCard_PickerPlaceholder", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_SelectDatePlaceholder: String {
            return LocalizedString(key: "6kA", originalKey: "Lark_Legacy_MsgCard_SelectDatePlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_SelectDatePlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6kA", originalKey: "Lark_Legacy_MsgCard_SelectDatePlaceholder", lang: __lang)
        }
        @inlinable
        public static var Lark_Legacy_MsgCard_SelectTimePlaceholder: String {
            return LocalizedString(key: "d3o", originalKey: "Lark_Legacy_MsgCard_SelectTimePlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Legacy_MsgCard_SelectTimePlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "d3o", originalKey: "Lark_Legacy_MsgCard_SelectTimePlaceholder", lang: __lang)
        }
        @inlinable
        public static var Lark_Settings_Cancel: String {
            return LocalizedString(key: "Tfc", originalKey: "Lark_Settings_Cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        public static func Lark_Settings_Cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Tfc", originalKey: "Lark_Settings_Cancel", lang: __lang)
        }
    }
}
// swiftlint:enable all
