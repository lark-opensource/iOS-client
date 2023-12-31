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
"Calendar_Common_Cancel":{
"hash":"glo",
"#vars":0
},
"Calendar_Common_Done":{
"hash":"YV4",
"#vars":0
},
"Calendar_Common_Ondate":{
"hash":"AWA",
"#vars":0
},
"Calendar_Detail_NoRepeat":{
"hash":"HiU",
"#vars":0
},
"Calendar_Edit_ChooseRepeat":{
"hash":"2hI",
"#vars":0
},
"Calendar_Edit_CustomRepeat":{
"hash":"dYo",
"#vars":0
},
"Calendar_Edit_Weekend":{
"hash":"8k4",
"#vars":0
},
"Calendar_RRule_Every":{
"hash":"xCQ",
"#vars":0
},
"Calendar_RRule_Fifth":{
"hash":"vFQ",
"#vars":0
},
"Calendar_RRule_First":{
"hash":"QRc",
"#vars":0
},
"Calendar_RRule_Fourth":{
"hash":"VNg",
"#vars":0
},
"Calendar_RRule_NeverEnds":{
"hash":"9+I",
"#vars":0
},
"Calendar_RRule_Second":{
"hash":"u90",
"#vars":0
},
"Calendar_RRule_Third":{
"hash":"5d4",
"#vars":0
},
"Calendar_RRule_Weekday":{
"hash":"GVU",
"#vars":0
},
"Calendar_RRule_WeeklyMobile":{
"hash":"BWA",
"#vars":0
},
"Calendar_Plural_RRuleDay":{
"hash":"jXc",
"#vars":1,
"icu_vars":["number"]
},
"Calendar_Plural_RRuleMonth":{
"hash":"lq8",
"#vars":1,
"icu_vars":["number"]
},
"Calendar_Plural_RRuleWeek":{
"hash":"TME",
"#vars":1,
"icu_vars":["number"]
},
"Calendar_Plural_RRuleYear":{
"hash":"rgA",
"#vars":1,
"icu_vars":["number"]
}
},
"name":"CTFoundation",
"short_key":true,
"config":{
"positional-args":false,
"use-native":false
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.CTFoundationAutoBundle, moduleName: "CTFoundation", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.CTFoundationAutoBundle, moduleName: "CTFoundation", lang: lang) ?? key
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
    final class RRule {
        @inlinable
        static var Calendar_Common_Cancel: String {
            return LocalizedString(key: "glo", originalKey: "Calendar_Common_Cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Common_Cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "glo", originalKey: "Calendar_Common_Cancel", lang: __lang)
        }
        @inlinable
        static var Calendar_Common_Done: String {
            return LocalizedString(key: "YV4", originalKey: "Calendar_Common_Done")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Common_Done(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YV4", originalKey: "Calendar_Common_Done", lang: __lang)
        }
        @inlinable
        static var Calendar_Common_Ondate: String {
            return LocalizedString(key: "AWA", originalKey: "Calendar_Common_Ondate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Common_Ondate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "AWA", originalKey: "Calendar_Common_Ondate", lang: __lang)
        }
        @inlinable
        static var Calendar_Detail_NoRepeat: String {
            return LocalizedString(key: "HiU", originalKey: "Calendar_Detail_NoRepeat")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Detail_NoRepeat(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HiU", originalKey: "Calendar_Detail_NoRepeat", lang: __lang)
        }
        @inlinable
        static var Calendar_Edit_ChooseRepeat: String {
            return LocalizedString(key: "2hI", originalKey: "Calendar_Edit_ChooseRepeat")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Edit_ChooseRepeat(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2hI", originalKey: "Calendar_Edit_ChooseRepeat", lang: __lang)
        }
        @inlinable
        static var Calendar_Edit_CustomRepeat: String {
            return LocalizedString(key: "dYo", originalKey: "Calendar_Edit_CustomRepeat")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Edit_CustomRepeat(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "dYo", originalKey: "Calendar_Edit_CustomRepeat", lang: __lang)
        }
        @inlinable
        static var Calendar_Edit_Weekend: String {
            return LocalizedString(key: "8k4", originalKey: "Calendar_Edit_Weekend")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Edit_Weekend(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "8k4", originalKey: "Calendar_Edit_Weekend", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_Every: String {
            return LocalizedString(key: "xCQ", originalKey: "Calendar_RRule_Every")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_Every(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "xCQ", originalKey: "Calendar_RRule_Every", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_Fifth: String {
            return LocalizedString(key: "vFQ", originalKey: "Calendar_RRule_Fifth")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_Fifth(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vFQ", originalKey: "Calendar_RRule_Fifth", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_First: String {
            return LocalizedString(key: "QRc", originalKey: "Calendar_RRule_First")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_First(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "QRc", originalKey: "Calendar_RRule_First", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_Fourth: String {
            return LocalizedString(key: "VNg", originalKey: "Calendar_RRule_Fourth")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_Fourth(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "VNg", originalKey: "Calendar_RRule_Fourth", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_NeverEnds: String {
            return LocalizedString(key: "9+I", originalKey: "Calendar_RRule_NeverEnds")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_NeverEnds(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9+I", originalKey: "Calendar_RRule_NeverEnds", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_Second: String {
            return LocalizedString(key: "u90", originalKey: "Calendar_RRule_Second")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_Second(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "u90", originalKey: "Calendar_RRule_Second", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_Third: String {
            return LocalizedString(key: "5d4", originalKey: "Calendar_RRule_Third")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_Third(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "5d4", originalKey: "Calendar_RRule_Third", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_Weekday: String {
            return LocalizedString(key: "GVU", originalKey: "Calendar_RRule_Weekday")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_Weekday(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "GVU", originalKey: "Calendar_RRule_Weekday", lang: __lang)
        }
        @inlinable
        static var Calendar_RRule_WeeklyMobile: String {
            return LocalizedString(key: "BWA", originalKey: "Calendar_RRule_WeeklyMobile")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_RRule_WeeklyMobile(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "BWA", originalKey: "Calendar_RRule_WeeklyMobile", lang: __lang)
        }
        @inlinable
        static var __Calendar_Plural_RRuleDay: String {
            return LocalizedString(key: "jXc", originalKey: "Calendar_Plural_RRuleDay")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_Plural_RRuleDay(number: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "jXc", originalKey: "Calendar_Plural_RRuleDay", lang: __lang)
            let args: [String: ICUFormattable] = [
              "number": `number`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Calendar_Plural_RRuleDay icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __Calendar_Plural_RRuleMonth: String {
            return LocalizedString(key: "lq8", originalKey: "Calendar_Plural_RRuleMonth")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_Plural_RRuleMonth(number: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "lq8", originalKey: "Calendar_Plural_RRuleMonth", lang: __lang)
            let args: [String: ICUFormattable] = [
              "number": `number`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Calendar_Plural_RRuleMonth icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __Calendar_Plural_RRuleWeek: String {
            return LocalizedString(key: "TME", originalKey: "Calendar_Plural_RRuleWeek")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_Plural_RRuleWeek(number: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "TME", originalKey: "Calendar_Plural_RRuleWeek", lang: __lang)
            let args: [String: ICUFormattable] = [
              "number": `number`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Calendar_Plural_RRuleWeek icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __Calendar_Plural_RRuleYear: String {
            return LocalizedString(key: "rgA", originalKey: "Calendar_Plural_RRuleYear")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_Plural_RRuleYear(number: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "rgA", originalKey: "Calendar_Plural_RRuleYear", lang: __lang)
            let args: [String: ICUFormattable] = [
              "number": `number`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Calendar_Plural_RRuleYear icu format with error: \(error)")
            }
            return template
        }
    }
}
// swiftlint:enable all
