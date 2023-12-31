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
"Lark_Chat_MapsSearchCustomLocation":{
"hash":"Je8",
"#vars":0
},
"Lark_Chat_MapsSearchInputLocation":{
"hash":"QD4",
"#vars":0
},
"Lark_Chat_MessageLocationMapApple":{
"hash":"FWY",
"#vars":0
},
"Lark_Chat_MessageLocationMapBaidu":{
"hash":"4vA",
"#vars":0
},
"Lark_Chat_MessageLocationMapGaode":{
"hash":"L90",
"#vars":0
},
"Lark_Chat_MessageLocationMapGoogle":{
"hash":"47A",
"#vars":0
},
"Lark_Chat_MessageLocationMapSougou":{
"hash":"07U",
"#vars":0
},
"Lark_Chat_MessageLocationMapTencent":{
"hash":"Ois",
"#vars":0
},
"Lark_Chat_MessageLocationMapWaze":{
"hash":"zcQ",
"#vars":0
},
"Lark_Chat_MessageLocationSendFailed":{
"hash":"bU8",
"#vars":0
},
"Lark_Chat_MessageLocationSending":{
"hash":"DZM",
"#vars":0
},
"Lark_Chat_MessageReplyStatusLocation":{
"hash":"xWE",
"#vars":1,
"normal_vars":["title"]
},
"Lark_Core_EnableLocationAccess_Button":{
"hash":"gi8",
"#vars":0
},
"Lark_Core_LocationAccess_Desc":{
"hash":"Eck",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_LocationAccess_Title":{
"hash":"32c",
"#vars":0
},
"Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry":{
"hash":"baU",
"#vars":0
},
"Lark_Core_MapServicesErrorMessage_NetworkErrorRetry":{
"hash":"nmk",
"#vars":0
},
"Lark_Core_MapServicesErrorMessage_NoLocationsFound":{
"hash":"NKM",
"#vars":0
},
"Lark_Core_MapServicesErrorMessage_NoPlacemarksFound":{
"hash":"EHk",
"#vars":0
},
"Lark_Core_MapServicesErrorMessage_UnableToFetchLocationsRetry":{
"hash":"rus",
"#vars":0
},
"Lark_Core_MapServicesErrorMessage_UnableToSearchRetry":{
"hash":"Qv0",
"#vars":0
},
"Lark_Legacy_ApplicationPhoneCallTimeCardSendSuccess":{
"hash":"zTk",
"#vars":0
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_LoadingFailed":{
"hash":"Flo",
"#vars":0
},
"Lark_Legacy_LoadingTip":{
"hash":"DTE",
"#vars":0
},
"Lark_Legacy_SearchNoMoreResult":{
"hash":"msU",
"#vars":0
},
"Lark_Legacy_SendToUser":{
"hash":"Fz0",
"#vars":0
}
},
"name":"LarkLocationPicker",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkLocationPickerAutoBundle, moduleName: "LarkLocationPicker", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkLocationPickerAutoBundle, moduleName: "LarkLocationPicker", lang: lang) ?? key
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
    final class LarkLocationPicker {
        @inlinable
        static var Lark_Chat_MapsSearchCustomLocation: String {
            return LocalizedString(key: "Je8", originalKey: "Lark_Chat_MapsSearchCustomLocation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MapsSearchCustomLocation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Je8", originalKey: "Lark_Chat_MapsSearchCustomLocation", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MapsSearchInputLocation: String {
            return LocalizedString(key: "QD4", originalKey: "Lark_Chat_MapsSearchInputLocation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MapsSearchInputLocation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "QD4", originalKey: "Lark_Chat_MapsSearchInputLocation", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapApple: String {
            return LocalizedString(key: "FWY", originalKey: "Lark_Chat_MessageLocationMapApple")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapApple(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "FWY", originalKey: "Lark_Chat_MessageLocationMapApple", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapBaidu: String {
            return LocalizedString(key: "4vA", originalKey: "Lark_Chat_MessageLocationMapBaidu")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapBaidu(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4vA", originalKey: "Lark_Chat_MessageLocationMapBaidu", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapGaode: String {
            return LocalizedString(key: "L90", originalKey: "Lark_Chat_MessageLocationMapGaode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapGaode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "L90", originalKey: "Lark_Chat_MessageLocationMapGaode", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapGoogle: String {
            return LocalizedString(key: "47A", originalKey: "Lark_Chat_MessageLocationMapGoogle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapGoogle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "47A", originalKey: "Lark_Chat_MessageLocationMapGoogle", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapSougou: String {
            return LocalizedString(key: "07U", originalKey: "Lark_Chat_MessageLocationMapSougou")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapSougou(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "07U", originalKey: "Lark_Chat_MessageLocationMapSougou", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapTencent: String {
            return LocalizedString(key: "Ois", originalKey: "Lark_Chat_MessageLocationMapTencent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapTencent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ois", originalKey: "Lark_Chat_MessageLocationMapTencent", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationMapWaze: String {
            return LocalizedString(key: "zcQ", originalKey: "Lark_Chat_MessageLocationMapWaze")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationMapWaze(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zcQ", originalKey: "Lark_Chat_MessageLocationMapWaze", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationSendFailed: String {
            return LocalizedString(key: "bU8", originalKey: "Lark_Chat_MessageLocationSendFailed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationSendFailed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bU8", originalKey: "Lark_Chat_MessageLocationSendFailed", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_MessageLocationSending: String {
            return LocalizedString(key: "DZM", originalKey: "Lark_Chat_MessageLocationSending")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageLocationSending(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "DZM", originalKey: "Lark_Chat_MessageLocationSending", lang: __lang)
        }
        @inlinable
        static var __Lark_Chat_MessageReplyStatusLocation: String {
            return LocalizedString(key: "xWE", originalKey: "Lark_Chat_MessageReplyStatusLocation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_MessageReplyStatusLocation(_ title: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Chat_MessageReplyStatusLocation(title: `title`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Chat_MessageReplyStatusLocation(title: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "xWE", originalKey: "Lark_Chat_MessageReplyStatusLocation", lang: __lang)
            template = template.replacingOccurrences(of: "{{title}}", with: "\(`title`)")
            return template
        }
        @inlinable
        static var Lark_Core_EnableLocationAccess_Button: String {
            return LocalizedString(key: "gi8", originalKey: "Lark_Core_EnableLocationAccess_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_EnableLocationAccess_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "gi8", originalKey: "Lark_Core_EnableLocationAccess_Button", lang: __lang)
        }
        @inlinable
        static var __Lark_Core_LocationAccess_Desc: String {
            return LocalizedString(key: "Eck", originalKey: "Lark_Core_LocationAccess_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_LocationAccess_Desc(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "Eck", originalKey: "Lark_Core_LocationAccess_Desc", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_Core_LocationAccess_Title: String {
            return LocalizedString(key: "32c", originalKey: "Lark_Core_LocationAccess_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_LocationAccess_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "32c", originalKey: "Lark_Core_LocationAccess_Title", lang: __lang)
        }
        @inlinable
        static var Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry: String {
            return LocalizedString(key: "baU", originalKey: "Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "baU", originalKey: "Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry", lang: __lang)
        }
        @inlinable
        static var Lark_Core_MapServicesErrorMessage_NetworkErrorRetry: String {
            return LocalizedString(key: "nmk", originalKey: "Lark_Core_MapServicesErrorMessage_NetworkErrorRetry")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_MapServicesErrorMessage_NetworkErrorRetry(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "nmk", originalKey: "Lark_Core_MapServicesErrorMessage_NetworkErrorRetry", lang: __lang)
        }
        @inlinable
        static var Lark_Core_MapServicesErrorMessage_NoLocationsFound: String {
            return LocalizedString(key: "NKM", originalKey: "Lark_Core_MapServicesErrorMessage_NoLocationsFound")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_MapServicesErrorMessage_NoLocationsFound(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NKM", originalKey: "Lark_Core_MapServicesErrorMessage_NoLocationsFound", lang: __lang)
        }
        @inlinable
        static var Lark_Core_MapServicesErrorMessage_NoPlacemarksFound: String {
            return LocalizedString(key: "EHk", originalKey: "Lark_Core_MapServicesErrorMessage_NoPlacemarksFound")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_MapServicesErrorMessage_NoPlacemarksFound(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "EHk", originalKey: "Lark_Core_MapServicesErrorMessage_NoPlacemarksFound", lang: __lang)
        }
        @inlinable
        static var Lark_Core_MapServicesErrorMessage_UnableToFetchLocationsRetry: String {
            return LocalizedString(key: "rus", originalKey: "Lark_Core_MapServicesErrorMessage_UnableToFetchLocationsRetry")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_MapServicesErrorMessage_UnableToFetchLocationsRetry(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "rus", originalKey: "Lark_Core_MapServicesErrorMessage_UnableToFetchLocationsRetry", lang: __lang)
        }
        @inlinable
        static var Lark_Core_MapServicesErrorMessage_UnableToSearchRetry: String {
            return LocalizedString(key: "Qv0", originalKey: "Lark_Core_MapServicesErrorMessage_UnableToSearchRetry")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_MapServicesErrorMessage_UnableToSearchRetry(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Qv0", originalKey: "Lark_Core_MapServicesErrorMessage_UnableToSearchRetry", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ApplicationPhoneCallTimeCardSendSuccess: String {
            return LocalizedString(key: "zTk", originalKey: "Lark_Legacy_ApplicationPhoneCallTimeCardSendSuccess")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ApplicationPhoneCallTimeCardSendSuccess(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zTk", originalKey: "Lark_Legacy_ApplicationPhoneCallTimeCardSendSuccess", lang: __lang)
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
        static var Lark_Legacy_LoadingFailed: String {
            return LocalizedString(key: "Flo", originalKey: "Lark_Legacy_LoadingFailed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LoadingFailed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Flo", originalKey: "Lark_Legacy_LoadingFailed", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_LoadingTip: String {
            return LocalizedString(key: "DTE", originalKey: "Lark_Legacy_LoadingTip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LoadingTip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "DTE", originalKey: "Lark_Legacy_LoadingTip", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SearchNoMoreResult: String {
            return LocalizedString(key: "msU", originalKey: "Lark_Legacy_SearchNoMoreResult")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SearchNoMoreResult(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "msU", originalKey: "Lark_Legacy_SearchNoMoreResult", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SendToUser: String {
            return LocalizedString(key: "Fz0", originalKey: "Lark_Legacy_SendToUser")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SendToUser(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Fz0", originalKey: "Lark_Legacy_SendToUser", lang: __lang)
        }
    }
}
// swiftlint:enable all
