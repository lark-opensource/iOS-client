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
"Calendar_StandardTime_DayOnlyString":{
"hash":"ktc",
"#vars":1,
"normal_vars":["numberDay"]
},
"Calendar_StandardTime_YearOnlyString":{
"hash":"PVg",
"#vars":1,
"normal_vars":["year"]
},
"Lark_Legacy_ChooseDate":{
"hash":"r2g",
"#vars":0
},
"Lark_Legacy_ChooseTime":{
"hash":"PeY",
"#vars":0
},
"Lark_Legacy_MsgCardCancel":{
"hash":"PUI",
"#vars":0
},
"Lark_Legacy_MsgCardConfirm":{
"hash":"nbQ",
"#vars":0
}
},
"name":"LarkDatePickerView",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkDatePickerViewAutoBundle, moduleName: "LarkDatePickerView", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkDatePickerViewAutoBundle, moduleName: "LarkDatePickerView", lang: lang) ?? key
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
    final class LarkDatePickerView {
        @inlinable
        static var __Calendar_StandardTime_DayOnlyString: String {
            return LocalizedString(key: "ktc", originalKey: "Calendar_StandardTime_DayOnlyString")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_StandardTime_DayOnlyString(_ numberDay: Any, lang __lang: Lang? = nil) -> String {
          return Calendar_StandardTime_DayOnlyString(numberDay: `numberDay`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_StandardTime_DayOnlyString(numberDay: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "ktc", originalKey: "Calendar_StandardTime_DayOnlyString", lang: __lang)
            template = template.replacingOccurrences(of: "{{numberDay}}", with: "\(`numberDay`)")
            return template
        }
        @inlinable
        static var __Calendar_StandardTime_YearOnlyString: String {
            return LocalizedString(key: "PVg", originalKey: "Calendar_StandardTime_YearOnlyString")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_StandardTime_YearOnlyString(_ year: Any, lang __lang: Lang? = nil) -> String {
          return Calendar_StandardTime_YearOnlyString(year: `year`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_StandardTime_YearOnlyString(year: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "PVg", originalKey: "Calendar_StandardTime_YearOnlyString", lang: __lang)
            template = template.replacingOccurrences(of: "{{year}}", with: "\(`year`)")
            return template
        }
        @inlinable
        static var Lark_Legacy_ChooseDate: String {
            return LocalizedString(key: "r2g", originalKey: "Lark_Legacy_ChooseDate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ChooseDate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "r2g", originalKey: "Lark_Legacy_ChooseDate", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ChooseTime: String {
            return LocalizedString(key: "PeY", originalKey: "Lark_Legacy_ChooseTime")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ChooseTime(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PeY", originalKey: "Lark_Legacy_ChooseTime", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_MsgCardCancel: String {
            return LocalizedString(key: "PUI", originalKey: "Lark_Legacy_MsgCardCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MsgCardCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PUI", originalKey: "Lark_Legacy_MsgCardCancel", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_MsgCardConfirm: String {
            return LocalizedString(key: "nbQ", originalKey: "Lark_Legacy_MsgCardConfirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MsgCardConfirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "nbQ", originalKey: "Lark_Legacy_MsgCardConfirm", lang: __lang)
        }
    }
}
// swiftlint:enable all
