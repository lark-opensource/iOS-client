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
"Lark_Chat_TopicCreateSelectVideoError":{
"hash":"clY",
"#vars":0
},
"Lark_IM_CodeBlockQuote_Text":{
"hash":"+mA",
"#vars":0
},
"Lark_IM_MessageSelfDestruct_1day_Option":{
"hash":"4c4",
"#vars":0
},
"Lark_IM_MessageSelfDestruct_1hour_Option":{
"hash":"rys",
"#vars":0
},
"Lark_IM_MessageSelfDestruct_1min_Option":{
"hash":"5Dk",
"#vars":0
},
"Lark_IM_MessageSelfDestruct_1month_Option":{
"hash":"Lnk",
"#vars":0
},
"Lark_IM_MessageSelfDestruct_1week_Option":{
"hash":"/WM",
"#vars":0
},
"Lark_IM_SelfDestructTimer_Hover":{
"hash":"ZaQ",
"#vars":0
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_ComposePostUploadPhoto":{
"hash":"qgk",
"#vars":0
},
"Lark_Legacy_ImageSummarize":{
"hash":"7KI",
"#vars":0
},
"Lark_Legacy_LoadingLoading":{
"hash":"/Vk",
"#vars":0
},
"Lark_Legacy_MessagePoVideo":{
"hash":"ReA",
"#vars":0
},
"Lark_Legacy_MsgFormatImage":{
"hash":"kL0",
"#vars":0
},
"Lark_Legacy_Processing":{
"hash":"d6g",
"#vars":0
},
"Lark_Chat_HideDocsURL":{
"hash":"gWM",
"#vars":1,
"icu_vars":["doctitle"]
},
"Lark_IM_CodeBlockNum_Text":{
"hash":"OWw",
"#vars":1,
"icu_vars":["num"]
},
"Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text":{
"hash":"IP8",
"#vars":1,
"icu_vars":["period"]
},
"MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text":{
"hash":"KDs",
"#vars":2,
"icu_vars":["command","content"]
},
"MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text":{
"hash":"TqY",
"#vars":2,
"icu_vars":["parameter","value"]
}
},
"name":"LarkBaseKeyboard",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkBaseKeyboardAutoBundle, moduleName: "LarkBaseKeyboard", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkBaseKeyboardAutoBundle, moduleName: "LarkBaseKeyboard", lang: lang) ?? key
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
    final class LarkBaseKeyboard {
        @inlinable
        static var Lark_Chat_TopicCreateSelectVideoError: String {
            return LocalizedString(key: "clY", originalKey: "Lark_Chat_TopicCreateSelectVideoError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_TopicCreateSelectVideoError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "clY", originalKey: "Lark_Chat_TopicCreateSelectVideoError", lang: __lang)
        }
        @inlinable
        static var Lark_IM_CodeBlockQuote_Text: String {
            return LocalizedString(key: "+mA", originalKey: "Lark_IM_CodeBlockQuote_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_CodeBlockQuote_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "+mA", originalKey: "Lark_IM_CodeBlockQuote_Text", lang: __lang)
        }
        @inlinable
        static var Lark_IM_MessageSelfDestruct_1day_Option: String {
            return LocalizedString(key: "4c4", originalKey: "Lark_IM_MessageSelfDestruct_1day_Option")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_MessageSelfDestruct_1day_Option(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4c4", originalKey: "Lark_IM_MessageSelfDestruct_1day_Option", lang: __lang)
        }
        @inlinable
        static var Lark_IM_MessageSelfDestruct_1hour_Option: String {
            return LocalizedString(key: "rys", originalKey: "Lark_IM_MessageSelfDestruct_1hour_Option")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_MessageSelfDestruct_1hour_Option(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "rys", originalKey: "Lark_IM_MessageSelfDestruct_1hour_Option", lang: __lang)
        }
        @inlinable
        static var Lark_IM_MessageSelfDestruct_1min_Option: String {
            return LocalizedString(key: "5Dk", originalKey: "Lark_IM_MessageSelfDestruct_1min_Option")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_MessageSelfDestruct_1min_Option(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "5Dk", originalKey: "Lark_IM_MessageSelfDestruct_1min_Option", lang: __lang)
        }
        @inlinable
        static var Lark_IM_MessageSelfDestruct_1month_Option: String {
            return LocalizedString(key: "Lnk", originalKey: "Lark_IM_MessageSelfDestruct_1month_Option")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_MessageSelfDestruct_1month_Option(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Lnk", originalKey: "Lark_IM_MessageSelfDestruct_1month_Option", lang: __lang)
        }
        @inlinable
        static var Lark_IM_MessageSelfDestruct_1week_Option: String {
            return LocalizedString(key: "/WM", originalKey: "Lark_IM_MessageSelfDestruct_1week_Option")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_MessageSelfDestruct_1week_Option(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/WM", originalKey: "Lark_IM_MessageSelfDestruct_1week_Option", lang: __lang)
        }
        @inlinable
        static var Lark_IM_SelfDestructTimer_Hover: String {
            return LocalizedString(key: "ZaQ", originalKey: "Lark_IM_SelfDestructTimer_Hover")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_SelfDestructTimer_Hover(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZaQ", originalKey: "Lark_IM_SelfDestructTimer_Hover", lang: __lang)
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
        static var Lark_Legacy_ComposePostUploadPhoto: String {
            return LocalizedString(key: "qgk", originalKey: "Lark_Legacy_ComposePostUploadPhoto")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ComposePostUploadPhoto(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qgk", originalKey: "Lark_Legacy_ComposePostUploadPhoto", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ImageSummarize: String {
            return LocalizedString(key: "7KI", originalKey: "Lark_Legacy_ImageSummarize")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ImageSummarize(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7KI", originalKey: "Lark_Legacy_ImageSummarize", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_LoadingLoading: String {
            return LocalizedString(key: "/Vk", originalKey: "Lark_Legacy_LoadingLoading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LoadingLoading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/Vk", originalKey: "Lark_Legacy_LoadingLoading", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_MessagePoVideo: String {
            return LocalizedString(key: "ReA", originalKey: "Lark_Legacy_MessagePoVideo")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MessagePoVideo(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ReA", originalKey: "Lark_Legacy_MessagePoVideo", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_MsgFormatImage: String {
            return LocalizedString(key: "kL0", originalKey: "Lark_Legacy_MsgFormatImage")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MsgFormatImage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "kL0", originalKey: "Lark_Legacy_MsgFormatImage", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Processing: String {
            return LocalizedString(key: "d6g", originalKey: "Lark_Legacy_Processing")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Processing(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "d6g", originalKey: "Lark_Legacy_Processing", lang: __lang)
        }
        @inlinable
        static var __Lark_Chat_HideDocsURL: String {
            return LocalizedString(key: "gWM", originalKey: "Lark_Chat_HideDocsURL")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Chat_HideDocsURL(doctitle: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "gWM", originalKey: "Lark_Chat_HideDocsURL", lang: __lang)
            let args: [String: ICUFormattable] = [
              "doctitle": `doctitle`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Lark_Chat_HideDocsURL icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __Lark_IM_CodeBlockNum_Text: String {
            return LocalizedString(key: "OWw", originalKey: "Lark_IM_CodeBlockNum_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_CodeBlockNum_Text(num: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "OWw", originalKey: "Lark_IM_CodeBlockNum_Text", lang: __lang)
            let args: [String: ICUFormattable] = [
              "num": `num`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Lark_IM_CodeBlockNum_Text icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text: String {
            return LocalizedString(key: "IP8", originalKey: "Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text(period: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "IP8", originalKey: "Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text", lang: __lang)
            let args: [String: ICUFormattable] = [
              "period": `period`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Lark_IM_NewMessagesWillSelfDestructInAPeriod_Server_Text icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text: String {
            return LocalizedString(key: "KDs", originalKey: "MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text(command: ICUValueConvertable, content: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "KDs", originalKey: "MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text", lang: __lang)
            let args: [String: ICUFormattable] = [
              "command": `command`.asICUFormattable(),
              "content": `content`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text icu format with error: \(error)")
            }
            return template
        }
        @inlinable
        static var __MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text: String {
            return LocalizedString(key: "TqY", originalKey: "MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text(parameter: ICUValueConvertable, value: ICUValueConvertable, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "TqY", originalKey: "MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text", lang: __lang)
            let args: [String: ICUFormattable] = [
              "parameter": `parameter`.asICUFormattable(),
              "value": `value`.asICUFormattable(),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text icu format with error: \(error)")
            }
            return template
        }
    }
}
// swiftlint:enable all
