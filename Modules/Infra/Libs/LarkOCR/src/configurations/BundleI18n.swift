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
"Lark_IM_ImageToText_CopyAll_Button":{
"hash":"4hA",
"#vars":0
},
"Lark_IM_ImageToText_CopySelectedText_Button":{
"hash":"Ptc",
"#vars":0
},
"Lark_IM_ImageToText_Copy_Button_Mobile":{
"hash":"PdA",
"#vars":0
},
"Lark_IM_ImageToText_ExtractAll_Button":{
"hash":"yaY",
"#vars":0
},
"Lark_IM_ImageToText_ExtractSelectedText_Button":{
"hash":"8oo",
"#vars":0
},
"Lark_IM_ImageToText_ExtractText_Close_Button":{
"hash":"WVg",
"#vars":0
},
"Lark_IM_ImageToText_ExtractText_Title":{
"hash":"ML4",
"#vars":0
},
"Lark_IM_ImageToText_FailedToExtractText_Toast":{
"hash":"55k",
"#vars":0
},
"Lark_IM_ImageToText_ForwardAll_Button":{
"hash":"PPI",
"#vars":0
},
"Lark_IM_ImageToText_ForwardSelectedText_Button":{
"hash":"Sos",
"#vars":0
},
"Lark_IM_ImageToText_Forward_Button_Mobile":{
"hash":"f4Y",
"#vars":0
},
"Lark_IM_ImageToText_NoTextFound_Text":{
"hash":"d4Q",
"#vars":0
},
"Lark_IM_ImageToText_ScrollWith2Fingers_Text":{
"hash":"2Cc",
"#vars":0
},
"Lark_IM_ImageToText_TapOrDragToSelectText":{
"hash":"eSA",
"#vars":0
},
"Lark_Legacy_NetworkError":{
"hash":"Km8",
"#vars":0
}
},
"name":"LarkOCR",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkOCRAutoBundle, moduleName: "LarkOCR", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkOCRAutoBundle, moduleName: "LarkOCR", lang: lang) ?? key
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
    final class LarkOCR {
        @inlinable
        static var Lark_IM_ImageToText_CopyAll_Button: String {
            return LocalizedString(key: "4hA", originalKey: "Lark_IM_ImageToText_CopyAll_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_CopyAll_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4hA", originalKey: "Lark_IM_ImageToText_CopyAll_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_CopySelectedText_Button: String {
            return LocalizedString(key: "Ptc", originalKey: "Lark_IM_ImageToText_CopySelectedText_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_CopySelectedText_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ptc", originalKey: "Lark_IM_ImageToText_CopySelectedText_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_Copy_Button_Mobile: String {
            return LocalizedString(key: "PdA", originalKey: "Lark_IM_ImageToText_Copy_Button_Mobile")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_Copy_Button_Mobile(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PdA", originalKey: "Lark_IM_ImageToText_Copy_Button_Mobile", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ExtractAll_Button: String {
            return LocalizedString(key: "yaY", originalKey: "Lark_IM_ImageToText_ExtractAll_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ExtractAll_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yaY", originalKey: "Lark_IM_ImageToText_ExtractAll_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ExtractSelectedText_Button: String {
            return LocalizedString(key: "8oo", originalKey: "Lark_IM_ImageToText_ExtractSelectedText_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ExtractSelectedText_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "8oo", originalKey: "Lark_IM_ImageToText_ExtractSelectedText_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ExtractText_Close_Button: String {
            return LocalizedString(key: "WVg", originalKey: "Lark_IM_ImageToText_ExtractText_Close_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ExtractText_Close_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "WVg", originalKey: "Lark_IM_ImageToText_ExtractText_Close_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ExtractText_Title: String {
            return LocalizedString(key: "ML4", originalKey: "Lark_IM_ImageToText_ExtractText_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ExtractText_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ML4", originalKey: "Lark_IM_ImageToText_ExtractText_Title", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_FailedToExtractText_Toast: String {
            return LocalizedString(key: "55k", originalKey: "Lark_IM_ImageToText_FailedToExtractText_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_FailedToExtractText_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "55k", originalKey: "Lark_IM_ImageToText_FailedToExtractText_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ForwardAll_Button: String {
            return LocalizedString(key: "PPI", originalKey: "Lark_IM_ImageToText_ForwardAll_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ForwardAll_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PPI", originalKey: "Lark_IM_ImageToText_ForwardAll_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ForwardSelectedText_Button: String {
            return LocalizedString(key: "Sos", originalKey: "Lark_IM_ImageToText_ForwardSelectedText_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ForwardSelectedText_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Sos", originalKey: "Lark_IM_ImageToText_ForwardSelectedText_Button", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_Forward_Button_Mobile: String {
            return LocalizedString(key: "f4Y", originalKey: "Lark_IM_ImageToText_Forward_Button_Mobile")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_Forward_Button_Mobile(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "f4Y", originalKey: "Lark_IM_ImageToText_Forward_Button_Mobile", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_NoTextFound_Text: String {
            return LocalizedString(key: "d4Q", originalKey: "Lark_IM_ImageToText_NoTextFound_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_NoTextFound_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "d4Q", originalKey: "Lark_IM_ImageToText_NoTextFound_Text", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_ScrollWith2Fingers_Text: String {
            return LocalizedString(key: "2Cc", originalKey: "Lark_IM_ImageToText_ScrollWith2Fingers_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_ScrollWith2Fingers_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2Cc", originalKey: "Lark_IM_ImageToText_ScrollWith2Fingers_Text", lang: __lang)
        }
        @inlinable
        static var Lark_IM_ImageToText_TapOrDragToSelectText: String {
            return LocalizedString(key: "eSA", originalKey: "Lark_IM_ImageToText_TapOrDragToSelectText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_ImageToText_TapOrDragToSelectText(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "eSA", originalKey: "Lark_IM_ImageToText_TapOrDragToSelectText", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NetworkError: String {
            return LocalizedString(key: "Km8", originalKey: "Lark_Legacy_NetworkError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NetworkError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Km8", originalKey: "Lark_Legacy_NetworkError", lang: __lang)
        }
    }
}
// swiftlint:enable all
