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
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_MsgCardCancel":{
"hash":"PUI",
"#vars":0
},
"Lark_Legacy_MsgCardSelect":{
"hash":"flM",
"#vars":0
},
"Lark_Legacy_MsgCard_LongImgTag":{
"hash":"SP0",
"#vars":0
},
"Lark_Legacy_Sure":{
"hash":"DrA",
"#vars":0
},
"Lark_Legacy_forwardCardToast":{
"hash":"/Hw",
"#vars":0
},
"OpenPlatform_CardCompt_UnknownUser":{
"hash":"PSw",
"#vars":0
},
"OpenPlatform_Common_Comma":{
"hash":"IvE",
"#vars":0
},
"OpenPlatform_UniversalCard_ClientMsgNotSupport":{
"hash":"G0o",
"#vars":0
},
"OpenPlatform_CardForMyAi_PplCntAppend":{
"hash":"ENg",
"#vars":1,
"icu_vars":["count"]
},
"OpenPlatform_CardForMyAi_PplCntMemberListTtl":{
"hash":"OVY",
"#vars":1,
"icu_vars":["count"]
},
"OpenPlatform_UniversalCard_ClientMsgExpired":{
"hash":"dKs",
"#vars":1,
"icu_vars":["day"]
},
"OpenPlatform_UniversalCard_ClientMsgUpdateNote":{
"hash":"wmY",
"#vars":1,
"icu_vars":["APP_DISPLAY_NAME"]
}
},
"name":"UniversalCardBase",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.UniversalCardBaseAutoBundle, moduleName: "UniversalCardBase", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.UniversalCardBaseAutoBundle, moduleName: "UniversalCardBase", lang: lang) ?? key
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
    final class UniversalCardBase {
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
        static var Lark_Legacy_MsgCardCancel: String {
            return LocalizedString(key: "PUI", originalKey: "Lark_Legacy_MsgCardCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MsgCardCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PUI", originalKey: "Lark_Legacy_MsgCardCancel", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_MsgCardSelect: String {
            return LocalizedString(key: "flM", originalKey: "Lark_Legacy_MsgCardSelect")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MsgCardSelect(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "flM", originalKey: "Lark_Legacy_MsgCardSelect", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_MsgCard_LongImgTag: String {
            return LocalizedString(key: "SP0", originalKey: "Lark_Legacy_MsgCard_LongImgTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MsgCard_LongImgTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "SP0", originalKey: "Lark_Legacy_MsgCard_LongImgTag", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Sure: String {
            return LocalizedString(key: "DrA", originalKey: "Lark_Legacy_Sure")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Sure(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "DrA", originalKey: "Lark_Legacy_Sure", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_forwardCardToast: String {
            return LocalizedString(key: "/Hw", originalKey: "Lark_Legacy_forwardCardToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_forwardCardToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/Hw", originalKey: "Lark_Legacy_forwardCardToast", lang: __lang)
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
        static var OpenPlatform_Common_Comma: String {
            return LocalizedString(key: "IvE", originalKey: "OpenPlatform_Common_Comma")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_Common_Comma(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "IvE", originalKey: "OpenPlatform_Common_Comma", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_UniversalCard_ClientMsgNotSupport: String {
            return LocalizedString(key: "G0o", originalKey: "OpenPlatform_UniversalCard_ClientMsgNotSupport")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_UniversalCard_ClientMsgNotSupport(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "G0o", originalKey: "OpenPlatform_UniversalCard_ClientMsgNotSupport", lang: __lang)
        }
        @inlinable
        static var __OpenPlatform_CardForMyAi_PplCntAppend: String {
            return LocalizedString(key: "ENg", originalKey: "OpenPlatform_CardForMyAi_PplCntAppend")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_CardForMyAi_PplCntAppend(count: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "ENg", originalKey: "OpenPlatform_CardForMyAi_PplCntAppend", lang: __lang)
            let args: [String: ICUFormattable] = [
              "count": `count`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("OpenPlatform_CardForMyAi_PplCntAppend icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __OpenPlatform_CardForMyAi_PplCntMemberListTtl: String {
            return LocalizedString(key: "OVY", originalKey: "OpenPlatform_CardForMyAi_PplCntMemberListTtl")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_CardForMyAi_PplCntMemberListTtl(count: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "OVY", originalKey: "OpenPlatform_CardForMyAi_PplCntMemberListTtl", lang: __lang)
            let args: [String: ICUFormattable] = [
              "count": `count`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("OpenPlatform_CardForMyAi_PplCntMemberListTtl icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __OpenPlatform_UniversalCard_ClientMsgExpired: String {
            return LocalizedString(key: "dKs", originalKey: "OpenPlatform_UniversalCard_ClientMsgExpired")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_UniversalCard_ClientMsgExpired(day: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "dKs", originalKey: "OpenPlatform_UniversalCard_ClientMsgExpired", lang: __lang)
            let args: [String: ICUFormattable] = [
              "day": `day`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("OpenPlatform_UniversalCard_ClientMsgExpired icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __OpenPlatform_UniversalCard_ClientMsgUpdateNote: String {
            return LocalizedString(key: "wmY", originalKey: "OpenPlatform_UniversalCard_ClientMsgUpdateNote")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_UniversalCard_ClientMsgUpdateNote(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "wmY", originalKey: "OpenPlatform_UniversalCard_ClientMsgUpdateNote", lang: __lang)
            let args: [String: ICUFormattable] = [
              "APP_DISPLAY_NAME": .string(LanguageManager.bundleDisplayName),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("OpenPlatform_UniversalCard_ClientMsgUpdateNote icu format with error: \(error)")
            }
            return template
        }
    }
}
// swiftlint:enable all
