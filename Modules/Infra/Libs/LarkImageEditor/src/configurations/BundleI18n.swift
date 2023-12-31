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
"Lark_ASL_NoTextOrPhotoRecognized":{
"hash":"ZTU",
"#vars":0
},
"Lark_ASL_OCRFail":{
"hash":"jEg",
"#vars":0
},
"Lark_ASL_PixelateOnboarding":{
"hash":"b8w",
"#vars":0
},
"Lark_ImageViewer_Arrow":{
"hash":"+aI",
"#vars":0
},
"Lark_ImageViewer_Cancel":{
"hash":"hjc",
"#vars":0
},
"Lark_ImageViewer_Confirm":{
"hash":"es4",
"#vars":0
},
"Lark_ImageViewer_Crop":{
"hash":"Q2M",
"#vars":0
},
"Lark_ImageViewer_Done":{
"hash":"bjI",
"#vars":0
},
"Lark_ImageViewer_DragHereToDelete":{
"hash":"Va8",
"#vars":0
},
"Lark_ImageViewer_Draw":{
"hash":"lSc",
"#vars":0
},
"Lark_ImageViewer_DrawPixelate":{
"hash":"GJc",
"#vars":0
},
"Lark_ImageViewer_Free":{
"hash":"4KQ",
"#vars":0
},
"Lark_ImageViewer_Oval":{
"hash":"eyQ",
"#vars":0
},
"Lark_ImageViewer_Pixelate":{
"hash":"yaA",
"#vars":0
},
"Lark_ImageViewer_Rectangle":{
"hash":"ZmE",
"#vars":0
},
"Lark_ImageViewer_ReleaseToDelete":{
"hash":"36A",
"#vars":0
},
"Lark_ImageViewer_Revert":{
"hash":"XCw",
"#vars":0
},
"Lark_ImageViewer_Rotate":{
"hash":"iDc",
"#vars":0
},
"Lark_ImageViewer_SelectPixelate":{
"hash":"0QY",
"#vars":0
},
"Lark_ImageViewer_Tag":{
"hash":"ETY",
"#vars":0
},
"Lark_ImageViewer_Text":{
"hash":"wNg",
"#vars":0
},
"Lark_Legacy_Back":{
"hash":"ong",
"#vars":0
},
"Lark_Legacy_ClickToEnter":{
"hash":"jmU",
"#vars":0
},
"Lark_Legacy_Finish":{
"hash":"TsQ",
"#vars":0
},
"Lark_Legacy_ImageEditCropper":{
"hash":"OKI",
"#vars":0
}
},
"name":"LarkImageEditor",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkImageEditorAutoBundle, moduleName: "LarkImageEditor", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkImageEditorAutoBundle, moduleName: "LarkImageEditor", lang: lang) ?? key
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
    final class LarkImageEditor {
        @inlinable
        static var Lark_ASL_NoTextOrPhotoRecognized: String {
            return LocalizedString(key: "ZTU", originalKey: "Lark_ASL_NoTextOrPhotoRecognized")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_NoTextOrPhotoRecognized(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZTU", originalKey: "Lark_ASL_NoTextOrPhotoRecognized", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_OCRFail: String {
            return LocalizedString(key: "jEg", originalKey: "Lark_ASL_OCRFail")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_OCRFail(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "jEg", originalKey: "Lark_ASL_OCRFail", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_PixelateOnboarding: String {
            return LocalizedString(key: "b8w", originalKey: "Lark_ASL_PixelateOnboarding")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_PixelateOnboarding(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "b8w", originalKey: "Lark_ASL_PixelateOnboarding", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Arrow: String {
            return LocalizedString(key: "+aI", originalKey: "Lark_ImageViewer_Arrow")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Arrow(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "+aI", originalKey: "Lark_ImageViewer_Arrow", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Cancel: String {
            return LocalizedString(key: "hjc", originalKey: "Lark_ImageViewer_Cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "hjc", originalKey: "Lark_ImageViewer_Cancel", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Confirm: String {
            return LocalizedString(key: "es4", originalKey: "Lark_ImageViewer_Confirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Confirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "es4", originalKey: "Lark_ImageViewer_Confirm", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Crop: String {
            return LocalizedString(key: "Q2M", originalKey: "Lark_ImageViewer_Crop")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Crop(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Q2M", originalKey: "Lark_ImageViewer_Crop", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Done: String {
            return LocalizedString(key: "bjI", originalKey: "Lark_ImageViewer_Done")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Done(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bjI", originalKey: "Lark_ImageViewer_Done", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_DragHereToDelete: String {
            return LocalizedString(key: "Va8", originalKey: "Lark_ImageViewer_DragHereToDelete")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_DragHereToDelete(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Va8", originalKey: "Lark_ImageViewer_DragHereToDelete", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Draw: String {
            return LocalizedString(key: "lSc", originalKey: "Lark_ImageViewer_Draw")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Draw(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lSc", originalKey: "Lark_ImageViewer_Draw", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_DrawPixelate: String {
            return LocalizedString(key: "GJc", originalKey: "Lark_ImageViewer_DrawPixelate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_DrawPixelate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "GJc", originalKey: "Lark_ImageViewer_DrawPixelate", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Free: String {
            return LocalizedString(key: "4KQ", originalKey: "Lark_ImageViewer_Free")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Free(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4KQ", originalKey: "Lark_ImageViewer_Free", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Oval: String {
            return LocalizedString(key: "eyQ", originalKey: "Lark_ImageViewer_Oval")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Oval(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "eyQ", originalKey: "Lark_ImageViewer_Oval", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Pixelate: String {
            return LocalizedString(key: "yaA", originalKey: "Lark_ImageViewer_Pixelate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Pixelate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yaA", originalKey: "Lark_ImageViewer_Pixelate", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Rectangle: String {
            return LocalizedString(key: "ZmE", originalKey: "Lark_ImageViewer_Rectangle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Rectangle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZmE", originalKey: "Lark_ImageViewer_Rectangle", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_ReleaseToDelete: String {
            return LocalizedString(key: "36A", originalKey: "Lark_ImageViewer_ReleaseToDelete")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_ReleaseToDelete(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "36A", originalKey: "Lark_ImageViewer_ReleaseToDelete", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Revert: String {
            return LocalizedString(key: "XCw", originalKey: "Lark_ImageViewer_Revert")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Revert(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "XCw", originalKey: "Lark_ImageViewer_Revert", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Rotate: String {
            return LocalizedString(key: "iDc", originalKey: "Lark_ImageViewer_Rotate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Rotate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iDc", originalKey: "Lark_ImageViewer_Rotate", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_SelectPixelate: String {
            return LocalizedString(key: "0QY", originalKey: "Lark_ImageViewer_SelectPixelate")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_SelectPixelate(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "0QY", originalKey: "Lark_ImageViewer_SelectPixelate", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Tag: String {
            return LocalizedString(key: "ETY", originalKey: "Lark_ImageViewer_Tag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Tag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ETY", originalKey: "Lark_ImageViewer_Tag", lang: __lang)
        }
        @inlinable
        static var Lark_ImageViewer_Text: String {
            return LocalizedString(key: "wNg", originalKey: "Lark_ImageViewer_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ImageViewer_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "wNg", originalKey: "Lark_ImageViewer_Text", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Back: String {
            return LocalizedString(key: "ong", originalKey: "Lark_Legacy_Back")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Back(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ong", originalKey: "Lark_Legacy_Back", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ClickToEnter: String {
            return LocalizedString(key: "jmU", originalKey: "Lark_Legacy_ClickToEnter")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ClickToEnter(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "jmU", originalKey: "Lark_Legacy_ClickToEnter", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Finish: String {
            return LocalizedString(key: "TsQ", originalKey: "Lark_Legacy_Finish")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Finish(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "TsQ", originalKey: "Lark_Legacy_Finish", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ImageEditCropper: String {
            return LocalizedString(key: "OKI", originalKey: "Lark_Legacy_ImageEditCropper")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ImageEditCropper(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "OKI", originalKey: "Lark_Legacy_ImageEditCropper", lang: __lang)
        }
    }
}
// swiftlint:enable all
