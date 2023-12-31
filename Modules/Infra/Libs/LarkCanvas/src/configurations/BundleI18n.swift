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
"Lark_Core_Delete":{
"hash":"w30",
"#vars":0
},
"Lark_Core_DeleteDraft":{
"hash":"YME",
"#vars":0
},
"Lark_Core_Discard":{
"hash":"eIk",
"#vars":0
},
"Lark_Core_PhotoAccessForSavePhoto":{
"hash":"BKU",
"#vars":0
},
"Lark_Core_PhotoAccessForSavePhoto_Desc":{
"hash":"0rg",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_Save":{
"hash":"NJQ",
"#vars":0
},
"Lark_Core_SaveDraft":{
"hash":"w64",
"#vars":0
},
"Lark_Docs_iPadWhiteboard_CancelChanges_Options":{
"hash":"nTQ",
"#vars":0
},
"Lark_Docs_iPadWhiteboard_SaveChanges_Options":{
"hash":"T7s",
"#vars":0
},
"Lark_Docs_iPadWhiteboard_SaveOrNot_Toast":{
"hash":"8aM",
"#vars":0
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_Completed":{
"hash":"4Qc",
"#vars":0
},
"Lark_Legacy_PhotoZoomingSaveImageFail":{
"hash":"gYw",
"#vars":0
},
"Lark_Legacy_QrCodeSaveToAlbum":{
"hash":"L+M",
"#vars":0
}
},
"name":"LarkCanvas",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkCanvasAutoBundle, moduleName: "LarkCanvas", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkCanvasAutoBundle, moduleName: "LarkCanvas", lang: lang) ?? key
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
    final class LarkCanvas {
        @inlinable
        static var Lark_Core_Delete: String {
            return LocalizedString(key: "w30", originalKey: "Lark_Core_Delete")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_Delete(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "w30", originalKey: "Lark_Core_Delete", lang: __lang)
        }
        @inlinable
        static var Lark_Core_DeleteDraft: String {
            return LocalizedString(key: "YME", originalKey: "Lark_Core_DeleteDraft")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_DeleteDraft(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YME", originalKey: "Lark_Core_DeleteDraft", lang: __lang)
        }
        @inlinable
        static var Lark_Core_Discard: String {
            return LocalizedString(key: "eIk", originalKey: "Lark_Core_Discard")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_Discard(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "eIk", originalKey: "Lark_Core_Discard", lang: __lang)
        }
        @inlinable
        static var Lark_Core_PhotoAccessForSavePhoto: String {
            return LocalizedString(key: "BKU", originalKey: "Lark_Core_PhotoAccessForSavePhoto")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_PhotoAccessForSavePhoto(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "BKU", originalKey: "Lark_Core_PhotoAccessForSavePhoto", lang: __lang)
        }
        @inlinable
        static var __Lark_Core_PhotoAccessForSavePhoto_Desc: String {
            return LocalizedString(key: "0rg", originalKey: "Lark_Core_PhotoAccessForSavePhoto_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_PhotoAccessForSavePhoto_Desc(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "0rg", originalKey: "Lark_Core_PhotoAccessForSavePhoto_Desc", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_Core_Save: String {
            return LocalizedString(key: "NJQ", originalKey: "Lark_Core_Save")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_Save(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NJQ", originalKey: "Lark_Core_Save", lang: __lang)
        }
        @inlinable
        static var Lark_Core_SaveDraft: String {
            return LocalizedString(key: "w64", originalKey: "Lark_Core_SaveDraft")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_SaveDraft(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "w64", originalKey: "Lark_Core_SaveDraft", lang: __lang)
        }
        @inlinable
        static var Lark_Docs_iPadWhiteboard_CancelChanges_Options: String {
            return LocalizedString(key: "nTQ", originalKey: "Lark_Docs_iPadWhiteboard_CancelChanges_Options")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Docs_iPadWhiteboard_CancelChanges_Options(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "nTQ", originalKey: "Lark_Docs_iPadWhiteboard_CancelChanges_Options", lang: __lang)
        }
        @inlinable
        static var Lark_Docs_iPadWhiteboard_SaveChanges_Options: String {
            return LocalizedString(key: "T7s", originalKey: "Lark_Docs_iPadWhiteboard_SaveChanges_Options")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Docs_iPadWhiteboard_SaveChanges_Options(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "T7s", originalKey: "Lark_Docs_iPadWhiteboard_SaveChanges_Options", lang: __lang)
        }
        @inlinable
        static var Lark_Docs_iPadWhiteboard_SaveOrNot_Toast: String {
            return LocalizedString(key: "8aM", originalKey: "Lark_Docs_iPadWhiteboard_SaveOrNot_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Docs_iPadWhiteboard_SaveOrNot_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "8aM", originalKey: "Lark_Docs_iPadWhiteboard_SaveOrNot_Toast", lang: __lang)
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
        static var Lark_Legacy_Completed: String {
            return LocalizedString(key: "4Qc", originalKey: "Lark_Legacy_Completed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Completed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4Qc", originalKey: "Lark_Legacy_Completed", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_PhotoZoomingSaveImageFail: String {
            return LocalizedString(key: "gYw", originalKey: "Lark_Legacy_PhotoZoomingSaveImageFail")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_PhotoZoomingSaveImageFail(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "gYw", originalKey: "Lark_Legacy_PhotoZoomingSaveImageFail", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_QrCodeSaveToAlbum: String {
            return LocalizedString(key: "L+M", originalKey: "Lark_Legacy_QrCodeSaveToAlbum")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_QrCodeSaveToAlbum(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "L+M", originalKey: "Lark_Legacy_QrCodeSaveToAlbum", lang: __lang)
        }
    }
}
// swiftlint:enable all
