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
"Calendar_Common_NoTitle":{
"hash":"JpQ",
"#vars":0
},
"Calendar_G_CanLinkDocsYouOwn_Desc":{
"hash":"Cos",
"#vars":0
},
"Calendar_G_ChooseToLink_Title":{
"hash":"pkA",
"#vars":0
},
"Lark_Event_AllDayEvent_Label":{
"hash":"d90",
"#vars":0
},
"Lark_Event_EventInProgress_Status":{
"hash":"q6w",
"#vars":0
},
"Lark_Event_NoAgendaForToday_Text":{
"hash":"PSY",
"#vars":0
},
"Lark_Event_NotificationsOff_Text":{
"hash":"E5w",
"#vars":0
},
"Lark_Feed_EventCenter_EventTitle":{
"hash":"tmI",
"#vars":0
},
"Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap":{
"hash":"xZE",
"#vars":2,
"icu_vars":["startTime","endTime"]
},
"Lark_Event_NumMoreEventsClickView_Mobile_Text":{
"hash":"gSE",
"#vars":1,
"icu_vars":["number"]
}
},
"name":"CalendarMod",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.CalendarModAutoBundle, moduleName: "CalendarMod", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.CalendarModAutoBundle, moduleName: "CalendarMod", lang: lang) ?? key
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
    final class CalendarMod {
        @inlinable
        static var Calendar_Common_NoTitle: String {
            return LocalizedString(key: "JpQ", originalKey: "Calendar_Common_NoTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_Common_NoTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "JpQ", originalKey: "Calendar_Common_NoTitle", lang: __lang)
        }
        @inlinable
        static var Calendar_G_CanLinkDocsYouOwn_Desc: String {
            return LocalizedString(key: "Cos", originalKey: "Calendar_G_CanLinkDocsYouOwn_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_G_CanLinkDocsYouOwn_Desc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Cos", originalKey: "Calendar_G_CanLinkDocsYouOwn_Desc", lang: __lang)
        }
        @inlinable
        static var Calendar_G_ChooseToLink_Title: String {
            return LocalizedString(key: "pkA", originalKey: "Calendar_G_ChooseToLink_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Calendar_G_ChooseToLink_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "pkA", originalKey: "Calendar_G_ChooseToLink_Title", lang: __lang)
        }
        @inlinable
        static var Lark_Event_AllDayEvent_Label: String {
            return LocalizedString(key: "d90", originalKey: "Lark_Event_AllDayEvent_Label")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Event_AllDayEvent_Label(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "d90", originalKey: "Lark_Event_AllDayEvent_Label", lang: __lang)
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
        static var Lark_Event_NoAgendaForToday_Text: String {
            return LocalizedString(key: "PSY", originalKey: "Lark_Event_NoAgendaForToday_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Event_NoAgendaForToday_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PSY", originalKey: "Lark_Event_NoAgendaForToday_Text", lang: __lang)
        }
        @inlinable
        static var Lark_Event_NotificationsOff_Text: String {
            return LocalizedString(key: "E5w", originalKey: "Lark_Event_NotificationsOff_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Event_NotificationsOff_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "E5w", originalKey: "Lark_Event_NotificationsOff_Text", lang: __lang)
        }
        @inlinable
        static var Lark_Feed_EventCenter_EventTitle: String {
            return LocalizedString(key: "tmI", originalKey: "Lark_Feed_EventCenter_EventTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Feed_EventCenter_EventTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tmI", originalKey: "Lark_Feed_EventCenter_EventTitle", lang: __lang)
        }
        @inlinable
        static var __Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap: String {
            return LocalizedString(key: "xZE", originalKey: "Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(startTime: ICUValueConvertable, endTime: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "xZE", originalKey: "Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap", lang: __lang)
            let args: [String: ICUFormattable] = [
              "startTime": `startTime`.asICUFormattable(),
              "endTime": `endTime`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __Lark_Event_NumMoreEventsClickView_Mobile_Text: String {
            return LocalizedString(key: "gSE", originalKey: "Lark_Event_NumMoreEventsClickView_Mobile_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Event_NumMoreEventsClickView_Mobile_Text(number: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "gSE", originalKey: "Lark_Event_NumMoreEventsClickView_Mobile_Text", lang: __lang)
            let args: [String: ICUFormattable] = [
              "number": `number`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Lark_Event_NumMoreEventsClickView_Mobile_Text icu format with error: \(error)")
            }
            return template
        }
    }
}
// swiftlint:enable all
