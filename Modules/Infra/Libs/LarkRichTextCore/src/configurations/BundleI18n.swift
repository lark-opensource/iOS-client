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
"Lark_IM_CodeBlockQuote_Text":{
"hash":"+mA",
"#vars":0
},
"Lark_IM_EditMessage_Edited_Label":{
"hash":"Qeg",
"#vars":0
},
"Lark_Legacy_ImageSummarize":{
"hash":"7KI",
"#vars":0
},
"Lark_Legacy_MessagePhoto":{
"hash":"c3w",
"#vars":0
},
"Lark_Legacy_MessagePoVideo":{
"hash":"ReA",
"#vars":0
},
"Lark_Legacy_VideoSummarize":{
"hash":"I5U",
"#vars":0
},
"MyAI_IM_UsedExtention_Text":{
"hash":"HI4",
"#vars":0
},
"MyAI_IM_UsedSpecificExtention_Text":{
"hash":"q5Q",
"#vars":1,
"normal_vars":["extension"]
},
"MyAI_IM_UsingExtention_Text":{
"hash":"wlc",
"#vars":0
},
"MyAI_IM_UsingSpecificExtention_Text":{
"hash":"kGc",
"#vars":1,
"normal_vars":["extension"]
},
"Lark_IM_CodeBlockNum_Text":{
"hash":"OWw",
"#vars":1,
"plurals_vars":["num"]
}
},
"name":"LarkRichTextCore",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkRichTextCoreAutoBundle, moduleName: "LarkRichTextCore", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkRichTextCoreAutoBundle, moduleName: "LarkRichTextCore", lang: lang) ?? key
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
    final class LarkRichTextCore {
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
        static var Lark_IM_EditMessage_Edited_Label: String {
            return LocalizedString(key: "Qeg", originalKey: "Lark_IM_EditMessage_Edited_Label")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_EditMessage_Edited_Label(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Qeg", originalKey: "Lark_IM_EditMessage_Edited_Label", lang: __lang)
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
        static var Lark_Legacy_MessagePhoto: String {
            return LocalizedString(key: "c3w", originalKey: "Lark_Legacy_MessagePhoto")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_MessagePhoto(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "c3w", originalKey: "Lark_Legacy_MessagePhoto", lang: __lang)
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
        static var Lark_Legacy_VideoSummarize: String {
            return LocalizedString(key: "I5U", originalKey: "Lark_Legacy_VideoSummarize")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_VideoSummarize(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "I5U", originalKey: "Lark_Legacy_VideoSummarize", lang: __lang)
        }
        @inlinable
        static var MyAI_IM_UsedExtention_Text: String {
            return LocalizedString(key: "HI4", originalKey: "MyAI_IM_UsedExtention_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func MyAI_IM_UsedExtention_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HI4", originalKey: "MyAI_IM_UsedExtention_Text", lang: __lang)
        }
        @inlinable
        static var __MyAI_IM_UsedSpecificExtention_Text: String {
            return LocalizedString(key: "q5Q", originalKey: "MyAI_IM_UsedSpecificExtention_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func MyAI_IM_UsedSpecificExtention_Text(_ extension: Any, lang __lang: Lang? = nil) -> String {
          return MyAI_IM_UsedSpecificExtention_Text(extension: `extension`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func MyAI_IM_UsedSpecificExtention_Text(extension: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "q5Q", originalKey: "MyAI_IM_UsedSpecificExtention_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{extension}}", with: "\(`extension`)")
            return template
        }
        @inlinable
        static var MyAI_IM_UsingExtention_Text: String {
            return LocalizedString(key: "wlc", originalKey: "MyAI_IM_UsingExtention_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func MyAI_IM_UsingExtention_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "wlc", originalKey: "MyAI_IM_UsingExtention_Text", lang: __lang)
        }
        @inlinable
        static var __MyAI_IM_UsingSpecificExtention_Text: String {
            return LocalizedString(key: "kGc", originalKey: "MyAI_IM_UsingSpecificExtention_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func MyAI_IM_UsingSpecificExtention_Text(_ extension: Any, lang __lang: Lang? = nil) -> String {
          return MyAI_IM_UsingSpecificExtention_Text(extension: `extension`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func MyAI_IM_UsingSpecificExtention_Text(extension: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "kGc", originalKey: "MyAI_IM_UsingSpecificExtention_Text", lang: __lang)
            template = template.replacingOccurrences(of: "{{extension}}", with: "\(`extension`)")
            return template
        }
        @inlinable
        static var __Lark_IM_CodeBlockNum_Text: String {
            return LocalizedString(key: "OWw", originalKey: "Lark_IM_CodeBlockNum_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_CodeBlockNum_Text(_ num: CVarArg, lang __lang: Lang? = nil) -> String {
          return Lark_IM_CodeBlockNum_Text(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_CodeBlockNum_Text(num: CVarArg, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "OWw", originalKey: "Lark_IM_CodeBlockNum_Text", lang: __lang)
            template = String.localizedStringWithFormat(template, `num`)
            return template
        }
    }
}
// swiftlint:enable all
