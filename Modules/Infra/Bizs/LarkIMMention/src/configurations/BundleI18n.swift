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
"Lark_Chat_AtChatMemberNoResults":{
"hash":"xnw",
"#vars":0
},
"Lark_Group_HugeGroup_MemberList_Bottom":{
"hash":"Op8",
"#vars":0
},
"Lark_IM_Mention_NoRecommendsSearchDocs_EmptyState":{
"hash":"9VY",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_All_Tab":{
"hash":"tIU",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_Docs_Tab":{
"hash":"loQ",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_MembersInThisChat_Title":{
"hash":"dRA",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_MembersNotInThisChat_Title":{
"hash":"q2E",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_Members_Tab":{
"hash":"lmw",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_MentionAll_Desc":{
"hash":"Sj8",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_MentionAll_Text":{
"hash":"tHw",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text":{
"hash":"x2M",
"#vars":0
},
"Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text":{
"hash":"Zy0",
"#vars":1,
"normal_vars":["name"]
},
"Lark_IM_SearchForMembersOrDocs_Placeholder":{
"hash":"ppg",
"#vars":0
},
"Lark_IM_SelectWhatToMention_Title":{
"hash":"Vu8",
"#vars":0
},
"Lark_IM_SelectedMentions_Title":{
"hash":"QnA",
"#vars":0
},
"Lark_IM_TheyWontReceiveThisMessage_Desc":{
"hash":"3W4",
"#vars":0
},
"Lark_Legacy_AllMember":{
"hash":"0vQ",
"#vars":0
},
"Lark_Legacy_ProbabilityAtPersonHint":{
"hash":"0LU",
"#vars":0
},
"Lark_Legacy_Sure":{
"hash":"DrA",
"#vars":0
},
"Lark_Mention_ErrorUnableToLoadNetworkError_Placeholder":{
"hash":"m4Y",
"#vars":0
},
"Lark_Mention_Multiselect_Mobile":{
"hash":"GhY",
"#vars":0
}
},
"name":"LarkIMMention",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkIMMentionAutoBundle, moduleName: "LarkIMMention", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkIMMentionAutoBundle, moduleName: "LarkIMMention", lang: lang) ?? key
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
    final class LarkIMMention {
        @inlinable
        static var Lark_Chat_AtChatMemberNoResults: String {
            return LocalizedString(key: "xnw", originalKey: "Lark_Chat_AtChatMemberNoResults")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_AtChatMemberNoResults(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "xnw", originalKey: "Lark_Chat_AtChatMemberNoResults", lang: __lang)
        }
        @inlinable
        static var Lark_Group_HugeGroup_MemberList_Bottom: String {
            return LocalizedString(key: "Op8", originalKey: "Lark_Group_HugeGroup_MemberList_Bottom")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Group_HugeGroup_MemberList_Bottom(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Op8", originalKey: "Lark_Group_HugeGroup_MemberList_Bottom", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Mention_NoRecommendsSearchDocs_EmptyState: String {
            return LocalizedString(key: "9VY", originalKey: "Lark_IM_Mention_NoRecommendsSearchDocs_EmptyState")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Mention_NoRecommendsSearchDocs_EmptyState(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9VY", originalKey: "Lark_IM_Mention_NoRecommendsSearchDocs_EmptyState", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_All_Tab: String {
            return LocalizedString(key: "tIU", originalKey: "Lark_IM_SearchForMembersOrDocs_All_Tab")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_All_Tab(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tIU", originalKey: "Lark_IM_SearchForMembersOrDocs_All_Tab", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_Docs_Tab: String {
            return LocalizedString(key: "loQ", originalKey: "Lark_IM_SearchForMembersOrDocs_Docs_Tab")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_Docs_Tab(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "loQ", originalKey: "Lark_IM_SearchForMembersOrDocs_Docs_Tab", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_MembersInThisChat_Title: String {
            return LocalizedString(key: "dRA", originalKey: "Lark_IM_SearchForMembersOrDocs_MembersInThisChat_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_MembersInThisChat_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "dRA", originalKey: "Lark_IM_SearchForMembersOrDocs_MembersInThisChat_Title", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_MembersNotInThisChat_Title: String {
            return LocalizedString(key: "q2E", originalKey: "Lark_IM_SearchForMembersOrDocs_MembersNotInThisChat_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_MembersNotInThisChat_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "q2E", originalKey: "Lark_IM_SearchForMembersOrDocs_MembersNotInThisChat_Title", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_Members_Tab: String {
            return LocalizedString(key: "lmw", originalKey: "Lark_IM_SearchForMembersOrDocs_Members_Tab")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_Members_Tab(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lmw", originalKey: "Lark_IM_SearchForMembersOrDocs_Members_Tab", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_MentionAll_Desc: String {
            return LocalizedString(key: "Sj8", originalKey: "Lark_IM_SearchForMembersOrDocs_MentionAll_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_MentionAll_Desc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Sj8", originalKey: "Lark_IM_SearchForMembersOrDocs_MentionAll_Desc", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_MentionAll_Text: String {
            return LocalizedString(key: "tHw", originalKey: "Lark_IM_SearchForMembersOrDocs_MentionAll_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_MentionAll_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tHw", originalKey: "Lark_IM_SearchForMembersOrDocs_MentionAll_Text", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text: String {
            return LocalizedString(key: "x2M", originalKey: "Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "x2M", originalKey: "Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text", lang: __lang)
        }
        @inlinable
        static var __Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text: String {
            return LocalizedString(key: "Zy0", originalKey: "Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text(_ name: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text(name: `name`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text(name: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "Zy0", originalKey: "Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{name}}", with: "\(`name`)")
            return template
        }
        @inlinable
        static var Lark_IM_SearchForMembersOrDocs_Placeholder: String {
            return LocalizedString(key: "ppg", originalKey: "Lark_IM_SearchForMembersOrDocs_Placeholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SearchForMembersOrDocs_Placeholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ppg", originalKey: "Lark_IM_SearchForMembersOrDocs_Placeholder", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SelectWhatToMention_Title: String {
            return LocalizedString(key: "Vu8", originalKey: "Lark_IM_SelectWhatToMention_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SelectWhatToMention_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Vu8", originalKey: "Lark_IM_SelectWhatToMention_Title", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SelectedMentions_Title: String {
            return LocalizedString(key: "QnA", originalKey: "Lark_IM_SelectedMentions_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SelectedMentions_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "QnA", originalKey: "Lark_IM_SelectedMentions_Title", lang: __lang)
        }
        @inlinable
        static var Lark_IM_TheyWontReceiveThisMessage_Desc: String {
            return LocalizedString(key: "3W4", originalKey: "Lark_IM_TheyWontReceiveThisMessage_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_TheyWontReceiveThisMessage_Desc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "3W4", originalKey: "Lark_IM_TheyWontReceiveThisMessage_Desc", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_AllMember: String {
            return LocalizedString(key: "0vQ", originalKey: "Lark_Legacy_AllMember")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_AllMember(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "0vQ", originalKey: "Lark_Legacy_AllMember", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ProbabilityAtPersonHint: String {
            return LocalizedString(key: "0LU", originalKey: "Lark_Legacy_ProbabilityAtPersonHint")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ProbabilityAtPersonHint(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "0LU", originalKey: "Lark_Legacy_ProbabilityAtPersonHint", lang: __lang)
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
        static var Lark_Mention_ErrorUnableToLoadNetworkError_Placeholder: String {
            return LocalizedString(key: "m4Y", originalKey: "Lark_Mention_ErrorUnableToLoadNetworkError_Placeholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Mention_ErrorUnableToLoadNetworkError_Placeholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "m4Y", originalKey: "Lark_Mention_ErrorUnableToLoadNetworkError_Placeholder", lang: __lang)
        }
        @inlinable
        static var Lark_Mention_Multiselect_Mobile: String {
            return LocalizedString(key: "GhY", originalKey: "Lark_Mention_Multiselect_Mobile")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Mention_Multiselect_Mobile(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "GhY", originalKey: "Lark_Mention_Multiselect_Mobile", lang: __lang)
        }
    }
}
// swiftlint:enable all
