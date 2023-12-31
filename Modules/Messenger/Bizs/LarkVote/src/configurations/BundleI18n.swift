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
"Lark_IM_Poll_CreatePoll_Anonymous":{
"hash":"TmY",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_MultipleAnswers":{
"hash":"yQs",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_Options_AddOptions_Button":{
"hash":"tvc",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_Options_Placeholder":{
"hash":"QRM",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_PollTitle_Placeholder":{
"hash":"NCM",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_Post_Button":{
"hash":"YLY",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_Title":{
"hash":"7L4",
"#vars":0
},
"Lark_IM_Poll_CreatePoll_TooManyOptions_Toast":{
"hash":"xE4",
"#vars":1,
"normal_vars":["num"]
},
"Lark_IM_Poll_MaximumCharacterLimit120_ErrorText":{
"hash":"EmU",
"#vars":1,
"normal_vars":["num"]
},
"Lark_IM_Poll_MaximumCharacterLimit60_ErrorText":{
"hash":"l80",
"#vars":1,
"normal_vars":["num"]
},
"Lark_IM_Poll_MultipleDuplicateOptions_ErrorText":{
"hash":"/RE",
"#vars":0
},
"Lark_IM_Poll_NoEmptyOption_Toast":{
"hash":"Dg4",
"#vars":0
},
"Lark_IM_Poll_NoEmptyTitle_Toast":{
"hash":"Sik",
"#vars":0
},
"Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText":{
"hash":"LDE",
"#vars":2,
"normal_vars":["Option1","Option2"]
},
"Lark_IM_Poll_UnableToPostPollTryLater_ErrorText":{
"hash":"Ru0",
"#vars":0
}
},
"name":"LarkVote",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkVoteAutoBundle, moduleName: "LarkVote", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkVoteAutoBundle, moduleName: "LarkVote", lang: lang) ?? key
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
    final class LarkVote {
        @inlinable
        static var Lark_IM_Poll_CreatePoll_Anonymous: String {
            return LocalizedString(key: "TmY", originalKey: "Lark_IM_Poll_CreatePoll_Anonymous")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_Anonymous(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "TmY", originalKey: "Lark_IM_Poll_CreatePoll_Anonymous", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_CreatePoll_MultipleAnswers: String {
            return LocalizedString(key: "yQs", originalKey: "Lark_IM_Poll_CreatePoll_MultipleAnswers")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_MultipleAnswers(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yQs", originalKey: "Lark_IM_Poll_CreatePoll_MultipleAnswers", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_CreatePoll_Options_AddOptions_Button: String {
            return LocalizedString(key: "tvc", originalKey: "Lark_IM_Poll_CreatePoll_Options_AddOptions_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_Options_AddOptions_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tvc", originalKey: "Lark_IM_Poll_CreatePoll_Options_AddOptions_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_CreatePoll_Options_Placeholder: String {
            return LocalizedString(key: "QRM", originalKey: "Lark_IM_Poll_CreatePoll_Options_Placeholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_Options_Placeholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "QRM", originalKey: "Lark_IM_Poll_CreatePoll_Options_Placeholder", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_CreatePoll_PollTitle_Placeholder: String {
            return LocalizedString(key: "NCM", originalKey: "Lark_IM_Poll_CreatePoll_PollTitle_Placeholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_PollTitle_Placeholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NCM", originalKey: "Lark_IM_Poll_CreatePoll_PollTitle_Placeholder", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_CreatePoll_Post_Button: String {
            return LocalizedString(key: "YLY", originalKey: "Lark_IM_Poll_CreatePoll_Post_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_Post_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YLY", originalKey: "Lark_IM_Poll_CreatePoll_Post_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_CreatePoll_Title: String {
            return LocalizedString(key: "7L4", originalKey: "Lark_IM_Poll_CreatePoll_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7L4", originalKey: "Lark_IM_Poll_CreatePoll_Title", lang: __lang)
        }
        @inlinable
        static var __Lark_IM_Poll_CreatePoll_TooManyOptions_Toast: String {
            return LocalizedString(key: "xE4", originalKey: "Lark_IM_Poll_CreatePoll_TooManyOptions_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_CreatePoll_TooManyOptions_Toast(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_Poll_CreatePoll_TooManyOptions_Toast(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_Poll_CreatePoll_TooManyOptions_Toast(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "xE4", originalKey: "Lark_IM_Poll_CreatePoll_TooManyOptions_Toast", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var __Lark_IM_Poll_MaximumCharacterLimit120_ErrorText: String {
            return LocalizedString(key: "EmU", originalKey: "Lark_IM_Poll_MaximumCharacterLimit120_ErrorText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_MaximumCharacterLimit120_ErrorText(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_Poll_MaximumCharacterLimit120_ErrorText(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_Poll_MaximumCharacterLimit120_ErrorText(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "EmU", originalKey: "Lark_IM_Poll_MaximumCharacterLimit120_ErrorText", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var __Lark_IM_Poll_MaximumCharacterLimit60_ErrorText: String {
            return LocalizedString(key: "l80", originalKey: "Lark_IM_Poll_MaximumCharacterLimit60_ErrorText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_MaximumCharacterLimit60_ErrorText(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_Poll_MaximumCharacterLimit60_ErrorText(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_Poll_MaximumCharacterLimit60_ErrorText(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "l80", originalKey: "Lark_IM_Poll_MaximumCharacterLimit60_ErrorText", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var Lark_IM_Poll_MultipleDuplicateOptions_ErrorText: String {
            return LocalizedString(key: "/RE", originalKey: "Lark_IM_Poll_MultipleDuplicateOptions_ErrorText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_MultipleDuplicateOptions_ErrorText(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/RE", originalKey: "Lark_IM_Poll_MultipleDuplicateOptions_ErrorText", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_NoEmptyOption_Toast: String {
            return LocalizedString(key: "Dg4", originalKey: "Lark_IM_Poll_NoEmptyOption_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_NoEmptyOption_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Dg4", originalKey: "Lark_IM_Poll_NoEmptyOption_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_IM_Poll_NoEmptyTitle_Toast: String {
            return LocalizedString(key: "Sik", originalKey: "Lark_IM_Poll_NoEmptyTitle_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_NoEmptyTitle_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Sik", originalKey: "Lark_IM_Poll_NoEmptyTitle_Toast", lang: __lang)
        }
        @inlinable
        static var __Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText: String {
            return LocalizedString(key: "LDE", originalKey: "Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText(_ Option1: Any, _ Option2: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText(Option1: `Option1`, Option2: `Option2`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText(Option1: Any, Option2: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "LDE", originalKey: "Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText", lang: __lang)
            template = template.replacingOccurrences(of: "{{Option1}}", with: "\(`Option1`)")
            template = template.replacingOccurrences(of: "{{Option2}}", with: "\(`Option2`)")
            return template
        }
        @inlinable
        static var Lark_IM_Poll_UnableToPostPollTryLater_ErrorText: String {
            return LocalizedString(key: "Ru0", originalKey: "Lark_IM_Poll_UnableToPostPollTryLater_ErrorText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Poll_UnableToPostPollTryLater_ErrorText(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ru0", originalKey: "Lark_IM_Poll_UnableToPostPollTryLater_ErrorText", lang: __lang)
        }
    }
}
// swiftlint:enable all
