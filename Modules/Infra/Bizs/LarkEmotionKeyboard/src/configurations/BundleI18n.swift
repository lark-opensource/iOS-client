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
"Lark_Chat_EmojiRecentlyUsed":{
"hash":"/4k",
"#vars":0
},
"Lark_IM_DefaultEmojis_Title":{
"hash":"K7g",
"#vars":0
},
"Lark_IM_FrequentlyUsedEmojis_Title":{
"hash":"oC4",
"#vars":0
},
"Lark_Legacy_ClickToAddStickers":{
"hash":"S9g",
"#vars":0
},
"Lark_Legacy_Send":{
"hash":"y3g",
"#vars":0
}
},
"name":"LarkEmotionKeyboard",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkEmotionKeyboardAutoBundle, moduleName: "LarkEmotionKeyboard", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkEmotionKeyboardAutoBundle, moduleName: "LarkEmotionKeyboard", lang: lang) ?? key
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
    final class LarkEmotionKeyboard {
        @inlinable
        static var Lark_Chat_EmojiRecentlyUsed: String {
            return LocalizedString(key: "/4k", originalKey: "Lark_Chat_EmojiRecentlyUsed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_EmojiRecentlyUsed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/4k", originalKey: "Lark_Chat_EmojiRecentlyUsed", lang: __lang)
        }
        @inlinable
        static var Lark_IM_DefaultEmojis_Title: String {
            return LocalizedString(key: "K7g", originalKey: "Lark_IM_DefaultEmojis_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_DefaultEmojis_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "K7g", originalKey: "Lark_IM_DefaultEmojis_Title", lang: __lang)
        }
        @inlinable
        static var Lark_IM_FrequentlyUsedEmojis_Title: String {
            return LocalizedString(key: "oC4", originalKey: "Lark_IM_FrequentlyUsedEmojis_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_FrequentlyUsedEmojis_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "oC4", originalKey: "Lark_IM_FrequentlyUsedEmojis_Title", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ClickToAddStickers: String {
            return LocalizedString(key: "S9g", originalKey: "Lark_Legacy_ClickToAddStickers")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ClickToAddStickers(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "S9g", originalKey: "Lark_Legacy_ClickToAddStickers", lang: __lang)
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
    }
}
// swiftlint:enable all
