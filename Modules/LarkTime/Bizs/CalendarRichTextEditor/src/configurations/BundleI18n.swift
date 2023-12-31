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
"Doc_Doc_Copy":{
"hash":"R7Y",
"#vars":0
},
"Doc_Doc_Paste":{
"hash":"JnU",
"#vars":0
},
"Doc_Normal_MenuCut":{
"hash":"T8I",
"#vars":0
},
"Doc_Normal_SelectAll":{
"hash":"fA0",
"#vars":0
},
"Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate":{
"hash":"nDM",
"#vars":0
}
},
"name":"CalendarRichTextEditor",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.CalendarRichTextEditorAutoBundle, moduleName: "CalendarRichTextEditor", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.CalendarRichTextEditorAutoBundle, moduleName: "CalendarRichTextEditor", lang: lang) ?? key
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
    final class CalendarRichTextEditor {
        @inlinable
        static var Doc_Doc_Copy: String {
            return LocalizedString(key: "R7Y", originalKey: "Doc_Doc_Copy")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Doc_Doc_Copy(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "R7Y", originalKey: "Doc_Doc_Copy", lang: __lang)
        }
        @inlinable
        static var Doc_Doc_Paste: String {
            return LocalizedString(key: "JnU", originalKey: "Doc_Doc_Paste")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Doc_Doc_Paste(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "JnU", originalKey: "Doc_Doc_Paste", lang: __lang)
        }
        @inlinable
        static var Doc_Normal_MenuCut: String {
            return LocalizedString(key: "T8I", originalKey: "Doc_Normal_MenuCut")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Doc_Normal_MenuCut(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "T8I", originalKey: "Doc_Normal_MenuCut", lang: __lang)
        }
        @inlinable
        static var Doc_Normal_SelectAll: String {
            return LocalizedString(key: "fA0", originalKey: "Doc_Normal_SelectAll")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Doc_Normal_SelectAll(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "fA0", originalKey: "Doc_Normal_SelectAll", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate: String {
            return LocalizedString(key: "nDM", originalKey: "Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "nDM", originalKey: "Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate", lang: __lang)
        }
    }
}
// swiftlint:enable all
