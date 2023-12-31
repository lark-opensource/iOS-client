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
"Lark_Chat_QuickswitcherUnpinClickToasts":{
"hash":"sE8",
"#vars":0
},
"Lark_Group_AnnouncementEditingIllegal":{
"hash":"3VA",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Groups_DocumentName":{
"hash":"KBo",
"#vars":0
},
"Lark_Groups_SelectedDocument":{
"hash":"Hvk",
"#vars":0
},
"Lark_Groups_TabNameErrorMsg":{
"hash":"VP4",
"#vars":0
},
"Lark_Legacy_AllResultLoaded":{
"hash":"6vs",
"#vars":0
},
"Lark_Legacy_Colon":{
"hash":"JS4",
"#vars":0
},
"Lark_Legacy_ConversationCreateDoc":{
"hash":"s8o",
"#vars":0
},
"Lark_Legacy_DefaultName":{
"hash":"2jY",
"#vars":0
},
"Lark_Legacy_DocsWidgetFail":{
"hash":"T74",
"#vars":0
},
"Lark_Legacy_DocsWidgetNotification":{
"hash":"m+I",
"#vars":0
},
"Lark_Legacy_External":{
"hash":"m0k",
"#vars":0
},
"Lark_Legacy_GroupAnnouncement":{
"hash":"J7k",
"#vars":0
},
"Lark_Legacy_NetworkErrorRetry":{
"hash":"Sd4",
"#vars":0
},
"Lark_Legacy_RecentEmpty":{
"hash":"9MY",
"#vars":0
},
"Lark_Legacy_Save":{
"hash":"yvI",
"#vars":0
},
"Lark_Legacy_SearchEmpty":{
"hash":"HkU",
"#vars":0
},
"Lark_Legacy_SelectedCountHint":{
"hash":"tUk",
"#vars":1,
"normal_vars":["select_count"]
},
"Lark_Legacy_Send":{
"hash":"y3g",
"#vars":0
},
"Lark_Legacy_SendChatAnnouncementFailed":{
"hash":"uaw",
"#vars":0
},
"Lark_Legacy_SendDocDocOwner":{
"hash":"cSw",
"#vars":0
},
"Lark_Legacy_SendDocLoading":{
"hash":"z9c",
"#vars":0
},
"Lark_Legacy_SendDocTitle":{
"hash":"eW4",
"#vars":0
},
"Lark_Legacy_Sending":{
"hash":"v2o",
"#vars":0
},
"Lark_Legacy_SentSuccessfully":{
"hash":"tcY",
"#vars":0
}
},
"name":"CCMMod",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.CCMModAutoBundle, moduleName: "CCMMod", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.CCMModAutoBundle, moduleName: "CCMMod", lang: lang) ?? key
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
    final class CCMMod {
        @inlinable
        static var Lark_Chat_QuickswitcherUnpinClickToasts: String {
            return LocalizedString(key: "sE8", originalKey: "Lark_Chat_QuickswitcherUnpinClickToasts")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_QuickswitcherUnpinClickToasts(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "sE8", originalKey: "Lark_Chat_QuickswitcherUnpinClickToasts", lang: __lang)
        }
        @inlinable
        static var __Lark_Group_AnnouncementEditingIllegal: String {
            return LocalizedString(key: "3VA", originalKey: "Lark_Group_AnnouncementEditingIllegal")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Group_AnnouncementEditingIllegal(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "3VA", originalKey: "Lark_Group_AnnouncementEditingIllegal", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_Groups_DocumentName: String {
            return LocalizedString(key: "KBo", originalKey: "Lark_Groups_DocumentName")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_DocumentName(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "KBo", originalKey: "Lark_Groups_DocumentName", lang: __lang)
        }
        @inlinable
        static var Lark_Groups_SelectedDocument: String {
            return LocalizedString(key: "Hvk", originalKey: "Lark_Groups_SelectedDocument")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_SelectedDocument(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Hvk", originalKey: "Lark_Groups_SelectedDocument", lang: __lang)
        }
        @inlinable
        static var Lark_Groups_TabNameErrorMsg: String {
            return LocalizedString(key: "VP4", originalKey: "Lark_Groups_TabNameErrorMsg")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_TabNameErrorMsg(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "VP4", originalKey: "Lark_Groups_TabNameErrorMsg", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_AllResultLoaded: String {
            return LocalizedString(key: "6vs", originalKey: "Lark_Legacy_AllResultLoaded")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_AllResultLoaded(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6vs", originalKey: "Lark_Legacy_AllResultLoaded", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Colon: String {
            return LocalizedString(key: "JS4", originalKey: "Lark_Legacy_Colon")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Colon(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "JS4", originalKey: "Lark_Legacy_Colon", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ConversationCreateDoc: String {
            return LocalizedString(key: "s8o", originalKey: "Lark_Legacy_ConversationCreateDoc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ConversationCreateDoc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "s8o", originalKey: "Lark_Legacy_ConversationCreateDoc", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_DefaultName: String {
            return LocalizedString(key: "2jY", originalKey: "Lark_Legacy_DefaultName")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_DefaultName(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2jY", originalKey: "Lark_Legacy_DefaultName", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_DocsWidgetFail: String {
            return LocalizedString(key: "T74", originalKey: "Lark_Legacy_DocsWidgetFail")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_DocsWidgetFail(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "T74", originalKey: "Lark_Legacy_DocsWidgetFail", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_DocsWidgetNotification: String {
            return LocalizedString(key: "m+I", originalKey: "Lark_Legacy_DocsWidgetNotification")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_DocsWidgetNotification(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "m+I", originalKey: "Lark_Legacy_DocsWidgetNotification", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_External: String {
            return LocalizedString(key: "m0k", originalKey: "Lark_Legacy_External")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_External(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "m0k", originalKey: "Lark_Legacy_External", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_GroupAnnouncement: String {
            return LocalizedString(key: "J7k", originalKey: "Lark_Legacy_GroupAnnouncement")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_GroupAnnouncement(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "J7k", originalKey: "Lark_Legacy_GroupAnnouncement", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NetworkErrorRetry: String {
            return LocalizedString(key: "Sd4", originalKey: "Lark_Legacy_NetworkErrorRetry")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NetworkErrorRetry(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Sd4", originalKey: "Lark_Legacy_NetworkErrorRetry", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_RecentEmpty: String {
            return LocalizedString(key: "9MY", originalKey: "Lark_Legacy_RecentEmpty")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_RecentEmpty(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9MY", originalKey: "Lark_Legacy_RecentEmpty", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Save: String {
            return LocalizedString(key: "yvI", originalKey: "Lark_Legacy_Save")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Save(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yvI", originalKey: "Lark_Legacy_Save", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SearchEmpty: String {
            return LocalizedString(key: "HkU", originalKey: "Lark_Legacy_SearchEmpty")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SearchEmpty(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HkU", originalKey: "Lark_Legacy_SearchEmpty", lang: __lang)
        }
        @inlinable
        static var __Lark_Legacy_SelectedCountHint: String {
            return LocalizedString(key: "tUk", originalKey: "Lark_Legacy_SelectedCountHint")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SelectedCountHint(_ select_count: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_SelectedCountHint(select_count: `select_count`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_SelectedCountHint(select_count: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "tUk", originalKey: "Lark_Legacy_SelectedCountHint", lang: __lang)
            template = template.replacingOccurrences(of: "{{select_count}}", with: "\(`select_count`)")
            return template
        }
        @inlinable
        static var Lark_Legacy_Send: String {
            return LocalizedString(key: "y3g", originalKey: "Lark_Legacy_Send")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Send(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "y3g", originalKey: "Lark_Legacy_Send", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SendChatAnnouncementFailed: String {
            return LocalizedString(key: "uaw", originalKey: "Lark_Legacy_SendChatAnnouncementFailed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SendChatAnnouncementFailed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "uaw", originalKey: "Lark_Legacy_SendChatAnnouncementFailed", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SendDocDocOwner: String {
            return LocalizedString(key: "cSw", originalKey: "Lark_Legacy_SendDocDocOwner")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SendDocDocOwner(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "cSw", originalKey: "Lark_Legacy_SendDocDocOwner", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SendDocLoading: String {
            return LocalizedString(key: "z9c", originalKey: "Lark_Legacy_SendDocLoading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SendDocLoading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "z9c", originalKey: "Lark_Legacy_SendDocLoading", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SendDocTitle: String {
            return LocalizedString(key: "eW4", originalKey: "Lark_Legacy_SendDocTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SendDocTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "eW4", originalKey: "Lark_Legacy_SendDocTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Sending: String {
            return LocalizedString(key: "v2o", originalKey: "Lark_Legacy_Sending")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Sending(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "v2o", originalKey: "Lark_Legacy_Sending", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SentSuccessfully: String {
            return LocalizedString(key: "tcY", originalKey: "Lark_Legacy_SentSuccessfully")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SentSuccessfully(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tcY", originalKey: "Lark_Legacy_SentSuccessfully", lang: __lang)
        }
    }
}
// swiftlint:enable all
