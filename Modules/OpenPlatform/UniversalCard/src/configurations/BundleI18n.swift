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
"Lark_InteractiveChart_ChartLoadingErr":{
"hash":"Ukc",
"#vars":0
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_TableComponentInCard_NoData":{
"hash":"gQ8",
"#vars":0
},
"OpenPlatform_CardCompt_UnknownUser":{
"hash":"PSw",
"#vars":0
},
"OpenPlatform_InteractiveChart_ChartComptLabel":{
"hash":"HvI",
"#vars":0
},
"OpenPlatform_MessageCard_Image":{
"hash":"YCs",
"#vars":0
},
"OpenPlatform_MessageCard_PlsEnterPlaceholder":{
"hash":"aeE",
"#vars":0
},
"OpenPlatform_MessageCard_RequiredItemLeftEmptyErr":{
"hash":"oLw",
"#vars":0
},
"OpenPlatform_MessageCard_Translation":{
"hash":"Jbw",
"#vars":0
},
"OpenPlatform_TableComponentInCard_TableInSummary":{
"hash":"P2A",
"#vars":0
},
"OpenPlatform_CardFallback_PlaceholderText":{
"hash":"PKE",
"#vars":1,
"icu_vars":["APP_DISPLAY_NAME"]
},
"OpenPlatform_MessageCard_TextLengthErr":{
"hash":"Bc8",
"#vars":1,
"icu_vars":["charCnt"]
}
},
"name":"UniversalCard",
"short_key":true,
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.UniversalCardAutoBundle, moduleName: "UniversalCard", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.UniversalCardAutoBundle, moduleName: "UniversalCard", lang: lang) ?? key
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
    final class UniversalCard {
        @inlinable
        static var Lark_InteractiveChart_ChartLoadingErr: String {
            return LocalizedString(key: "Ukc", originalKey: "Lark_InteractiveChart_ChartLoadingErr")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_InteractiveChart_ChartLoadingErr(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ukc", originalKey: "Lark_InteractiveChart_ChartLoadingErr", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Cancel: String {
            return LocalizedString(key: "ewo", originalKey: "Lark_Legacy_Cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ewo", originalKey: "Lark_Legacy_Cancel", lang: __lang)
        }
        @inlinable
        static var Lark_TableComponentInCard_NoData: String {
            return LocalizedString(key: "gQ8", originalKey: "Lark_TableComponentInCard_NoData")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_TableComponentInCard_NoData(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "gQ8", originalKey: "Lark_TableComponentInCard_NoData", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_CardCompt_UnknownUser: String {
            return LocalizedString(key: "PSw", originalKey: "OpenPlatform_CardCompt_UnknownUser")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_CardCompt_UnknownUser(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PSw", originalKey: "OpenPlatform_CardCompt_UnknownUser", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_InteractiveChart_ChartComptLabel: String {
            return LocalizedString(key: "HvI", originalKey: "OpenPlatform_InteractiveChart_ChartComptLabel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_InteractiveChart_ChartComptLabel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HvI", originalKey: "OpenPlatform_InteractiveChart_ChartComptLabel", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MessageCard_Image: String {
            return LocalizedString(key: "YCs", originalKey: "OpenPlatform_MessageCard_Image")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MessageCard_Image(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YCs", originalKey: "OpenPlatform_MessageCard_Image", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MessageCard_PlsEnterPlaceholder: String {
            return LocalizedString(key: "aeE", originalKey: "OpenPlatform_MessageCard_PlsEnterPlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MessageCard_PlsEnterPlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "aeE", originalKey: "OpenPlatform_MessageCard_PlsEnterPlaceholder", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MessageCard_RequiredItemLeftEmptyErr: String {
            return LocalizedString(key: "oLw", originalKey: "OpenPlatform_MessageCard_RequiredItemLeftEmptyErr")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MessageCard_RequiredItemLeftEmptyErr(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "oLw", originalKey: "OpenPlatform_MessageCard_RequiredItemLeftEmptyErr", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MessageCard_Translation: String {
            return LocalizedString(key: "Jbw", originalKey: "OpenPlatform_MessageCard_Translation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MessageCard_Translation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Jbw", originalKey: "OpenPlatform_MessageCard_Translation", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_TableComponentInCard_TableInSummary: String {
            return LocalizedString(key: "P2A", originalKey: "OpenPlatform_TableComponentInCard_TableInSummary")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_TableComponentInCard_TableInSummary(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "P2A", originalKey: "OpenPlatform_TableComponentInCard_TableInSummary", lang: __lang)
        }
        @inlinable
        static var __OpenPlatform_CardFallback_PlaceholderText: String {
            return LocalizedString(key: "PKE", originalKey: "OpenPlatform_CardFallback_PlaceholderText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_CardFallback_PlaceholderText(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "PKE", originalKey: "OpenPlatform_CardFallback_PlaceholderText", lang: __lang)
            let args: [String: ICUFormattable] = [
              "APP_DISPLAY_NAME": .string(LanguageManager.bundleDisplayName),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("OpenPlatform_CardFallback_PlaceholderText icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __OpenPlatform_MessageCard_TextLengthErr: String {
            return LocalizedString(key: "Bc8", originalKey: "OpenPlatform_MessageCard_TextLengthErr")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_MessageCard_TextLengthErr(charCnt: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "Bc8", originalKey: "OpenPlatform_MessageCard_TextLengthErr", lang: __lang)
            let args: [String: ICUFormattable] = [
              "charCnt": `charCnt`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("OpenPlatform_MessageCard_TextLengthErr icu format with error: \(error)")
            }
            return template
        }
    }
}
// swiftlint:enable all
