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
"Lark_ASL_RecognizeText":{
"hash":"WMo",
"#vars":0
},
"Lark_ASL_ScanQRCode":{
"hash":"qWU",
"#vars":0
},
"Lark_ASL_SelectTextRegion":{
"hash":"HyU",
"#vars":0
},
"Lark_ASL_TapToTurnOffLight":{
"hash":"pbo",
"#vars":0
},
"Lark_ASL_TapToTurnOnLight":{
"hash":"w44",
"#vars":0
},
"Lark_Core_AddToPhoneContacts_Cancel_Button":{
"hash":"xAQ",
"#vars":0
},
"Lark_Core_CameraAccessForScanCode_Desc":{
"hash":"RZg",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_CameraAccess_Title":{
"hash":"L4Q",
"#vars":0
},
"Lark_Legacy_BaseUiLoading":{
"hash":"ciI",
"#vars":0
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_ConfirmSure":{
"hash":"Tac",
"#vars":0
},
"Lark_Legacy_Hint":{
"hash":"4L8",
"#vars":0
},
"Lark_Legacy_LarkScan":{
"hash":"qXI",
"#vars":0
},
"Lark_Legacy_NetworkOrServiceError":{
"hash":"kTU",
"#vars":0
},
"Lark_Legacy_QrCodeAlbum":{
"hash":"ppg",
"#vars":0
},
"Lark_Legacy_QrCodeDeviceError":{
"hash":"9xY",
"#vars":0
},
"Lark_Legacy_QrCodeNotFound":{
"hash":"FLI",
"#vars":0
},
"Lark_Legacy_Sure":{
"hash":"DrA",
"#vars":0
},
"Lark_Legacy_iPadSplitViewCamera":{
"hash":"lSc",
"#vars":0
},
"Lark_QRcodeScan_MultiCodeTapToChoose_Text":{
"hash":"1cY",
"#vars":0
},
"Lark_ScanCode_TapToTurnLightOff_Button":{
"hash":"UQg",
"#vars":0
},
"Lark_ScanCode_TapToTurnLightOn_Button":{
"hash":"aDk",
"#vars":0
}
},
"name":"QRCode",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.QRCodeAutoBundle, moduleName: "QRCode", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.QRCodeAutoBundle, moduleName: "QRCode", lang: lang) ?? key
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
    final class QRCode {
        @inlinable
        static var Lark_ASL_RecognizeText: String {
            return LocalizedString(key: "WMo", originalKey: "Lark_ASL_RecognizeText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_RecognizeText(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "WMo", originalKey: "Lark_ASL_RecognizeText", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_ScanQRCode: String {
            return LocalizedString(key: "qWU", originalKey: "Lark_ASL_ScanQRCode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_ScanQRCode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qWU", originalKey: "Lark_ASL_ScanQRCode", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_SelectTextRegion: String {
            return LocalizedString(key: "HyU", originalKey: "Lark_ASL_SelectTextRegion")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_SelectTextRegion(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HyU", originalKey: "Lark_ASL_SelectTextRegion", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_TapToTurnOffLight: String {
            return LocalizedString(key: "pbo", originalKey: "Lark_ASL_TapToTurnOffLight")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_TapToTurnOffLight(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "pbo", originalKey: "Lark_ASL_TapToTurnOffLight", lang: __lang)
        }
        @inlinable
        static var Lark_ASL_TapToTurnOnLight: String {
            return LocalizedString(key: "w44", originalKey: "Lark_ASL_TapToTurnOnLight")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ASL_TapToTurnOnLight(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "w44", originalKey: "Lark_ASL_TapToTurnOnLight", lang: __lang)
        }
        @inlinable
        static var Lark_Core_AddToPhoneContacts_Cancel_Button: String {
            return LocalizedString(key: "xAQ", originalKey: "Lark_Core_AddToPhoneContacts_Cancel_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_AddToPhoneContacts_Cancel_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "xAQ", originalKey: "Lark_Core_AddToPhoneContacts_Cancel_Button", lang: __lang)
        }
        @inlinable
        static var __Lark_Core_CameraAccessForScanCode_Desc: String {
            return LocalizedString(key: "RZg", originalKey: "Lark_Core_CameraAccessForScanCode_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_CameraAccessForScanCode_Desc(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "RZg", originalKey: "Lark_Core_CameraAccessForScanCode_Desc", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_Core_CameraAccess_Title: String {
            return LocalizedString(key: "L4Q", originalKey: "Lark_Core_CameraAccess_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_CameraAccess_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "L4Q", originalKey: "Lark_Core_CameraAccess_Title", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_BaseUiLoading: String {
            return LocalizedString(key: "ciI", originalKey: "Lark_Legacy_BaseUiLoading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_BaseUiLoading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ciI", originalKey: "Lark_Legacy_BaseUiLoading", lang: __lang)
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
        static var Lark_Legacy_ConfirmSure: String {
            return LocalizedString(key: "Tac", originalKey: "Lark_Legacy_ConfirmSure")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ConfirmSure(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Tac", originalKey: "Lark_Legacy_ConfirmSure", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Hint: String {
            return LocalizedString(key: "4L8", originalKey: "Lark_Legacy_Hint")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Hint(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4L8", originalKey: "Lark_Legacy_Hint", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_LarkScan: String {
            return LocalizedString(key: "qXI", originalKey: "Lark_Legacy_LarkScan")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LarkScan(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qXI", originalKey: "Lark_Legacy_LarkScan", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NetworkOrServiceError: String {
            return LocalizedString(key: "kTU", originalKey: "Lark_Legacy_NetworkOrServiceError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NetworkOrServiceError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "kTU", originalKey: "Lark_Legacy_NetworkOrServiceError", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_QrCodeAlbum: String {
            return LocalizedString(key: "ppg", originalKey: "Lark_Legacy_QrCodeAlbum")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_QrCodeAlbum(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ppg", originalKey: "Lark_Legacy_QrCodeAlbum", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_QrCodeDeviceError: String {
            return LocalizedString(key: "9xY", originalKey: "Lark_Legacy_QrCodeDeviceError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_QrCodeDeviceError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9xY", originalKey: "Lark_Legacy_QrCodeDeviceError", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_QrCodeNotFound: String {
            return LocalizedString(key: "FLI", originalKey: "Lark_Legacy_QrCodeNotFound")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_QrCodeNotFound(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "FLI", originalKey: "Lark_Legacy_QrCodeNotFound", lang: __lang)
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
        static var Lark_Legacy_iPadSplitViewCamera: String {
            return LocalizedString(key: "lSc", originalKey: "Lark_Legacy_iPadSplitViewCamera")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_iPadSplitViewCamera(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lSc", originalKey: "Lark_Legacy_iPadSplitViewCamera", lang: __lang)
        }
        @inlinable
        static var Lark_QRcodeScan_MultiCodeTapToChoose_Text: String {
            return LocalizedString(key: "1cY", originalKey: "Lark_QRcodeScan_MultiCodeTapToChoose_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_QRcodeScan_MultiCodeTapToChoose_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "1cY", originalKey: "Lark_QRcodeScan_MultiCodeTapToChoose_Text", lang: __lang)
        }
        @inlinable
        static var Lark_ScanCode_TapToTurnLightOff_Button: String {
            return LocalizedString(key: "UQg", originalKey: "Lark_ScanCode_TapToTurnLightOff_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ScanCode_TapToTurnLightOff_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "UQg", originalKey: "Lark_ScanCode_TapToTurnLightOff_Button", lang: __lang)
        }
        @inlinable
        static var Lark_ScanCode_TapToTurnLightOn_Button: String {
            return LocalizedString(key: "aDk", originalKey: "Lark_ScanCode_TapToTurnLightOn_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_ScanCode_TapToTurnLightOn_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "aDk", originalKey: "Lark_ScanCode_TapToTurnLightOn_Button", lang: __lang)
        }
    }
}
// swiftlint:enable all
