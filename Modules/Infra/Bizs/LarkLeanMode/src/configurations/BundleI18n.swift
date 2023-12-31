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
"Lark_Security_LeanModeAccessRemovedPopUpContent":{
"hash":"iHI",
"#vars":0
},
"Lark_Security_LeanModeConfirmForcedOffPopUpButtonConfirm":{
"hash":"czc",
"#vars":0
},
"Lark_Security_LeanModeConfirmForcedOffPopUpContent":{
"hash":"F4I",
"#vars":0
},
"Lark_Security_LeanModeConfirmTurnOffPopUpTitle":{
"hash":"ZFU",
"#vars":0
},
"Lark_Security_LeanModeConfirmTurnOnPopUpChoice":{
"hash":"kZ8",
"#vars":0
},
"Lark_Security_LeanModeConfirmTurnOnPopUpTitle":{
"hash":"tCE",
"#vars":0
},
"Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonRemindLater":{
"hash":"9ew",
"#vars":0
},
"Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonSetNow":{
"hash":"5sU",
"#vars":0
},
"Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpContentMobile":{
"hash":"7+E",
"#vars":0
},
"Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpTitle":{
"hash":"Uxg",
"#vars":0
},
"Lark_Security_LeanModePopUpGeneralAckButton":{
"hash":"L3o",
"#vars":0
},
"Lark_Security_LeanModePopUpGeneralButtonConfirm":{
"hash":"2D8",
"#vars":0
},
"Lark_Security_LeanModePopUpGeneralTitle":{
"hash":"iRw",
"#vars":0
},
"Lark_Security_LeanModeSomethingWentWrongGeneralToast":{
"hash":"bfM",
"#vars":0
},
"Lark_Security_LeanModeSwitchModePrepareLoading":{
"hash":"LTM",
"#vars":0
},
"Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpButton":{
"hash":"ZMU",
"#vars":0
},
"Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpContent":{
"hash":"Ts8",
"#vars":0
},
"Lark_Security_LeanModeTurnOffIdentityVerificationPageButton":{
"hash":"wPg",
"#vars":0
},
"Lark_Security_LeanModeTurnOffIdentityVerificationPageContent":{
"hash":"n6o",
"#vars":0
},
"Lark_Security_LeanModeTurnOffIdentityVerificationPageTitle":{
"hash":"bas",
"#vars":0
},
"Lark_Security_LeanModeTurnOffNoAccessContent":{
"hash":"YbY",
"#vars":0
},
"Lark_Security_LeanModeTurnOffOtherDeviceButtonForAll":{
"hash":"/JE",
"#vars":0
},
"Lark_Security_LeanModeTurnOffOtherDeviceButtonJustThis":{
"hash":"hHg",
"#vars":0
},
"Lark_Security_LeanModeTurnOffOtherDeviceContent":{
"hash":"8kE",
"#vars":0
},
"Lark_Security_LeanModeTurnOffOtherDeviceTitle":{
"hash":"vzA",
"#vars":0
}
},
"name":"LarkLeanMode",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkLeanModeAutoBundle, moduleName: "LarkLeanMode", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkLeanModeAutoBundle, moduleName: "LarkLeanMode", lang: lang) ?? key
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
    final class LarkLeanMode {
        @inlinable
        static var Lark_Security_LeanModeAccessRemovedPopUpContent: String {
            return LocalizedString(key: "iHI", originalKey: "Lark_Security_LeanModeAccessRemovedPopUpContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeAccessRemovedPopUpContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iHI", originalKey: "Lark_Security_LeanModeAccessRemovedPopUpContent", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeConfirmForcedOffPopUpButtonConfirm: String {
            return LocalizedString(key: "czc", originalKey: "Lark_Security_LeanModeConfirmForcedOffPopUpButtonConfirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeConfirmForcedOffPopUpButtonConfirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "czc", originalKey: "Lark_Security_LeanModeConfirmForcedOffPopUpButtonConfirm", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeConfirmForcedOffPopUpContent: String {
            return LocalizedString(key: "F4I", originalKey: "Lark_Security_LeanModeConfirmForcedOffPopUpContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeConfirmForcedOffPopUpContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "F4I", originalKey: "Lark_Security_LeanModeConfirmForcedOffPopUpContent", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeConfirmTurnOffPopUpTitle: String {
            return LocalizedString(key: "ZFU", originalKey: "Lark_Security_LeanModeConfirmTurnOffPopUpTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeConfirmTurnOffPopUpTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZFU", originalKey: "Lark_Security_LeanModeConfirmTurnOffPopUpTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeConfirmTurnOnPopUpChoice: String {
            return LocalizedString(key: "kZ8", originalKey: "Lark_Security_LeanModeConfirmTurnOnPopUpChoice")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeConfirmTurnOnPopUpChoice(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "kZ8", originalKey: "Lark_Security_LeanModeConfirmTurnOnPopUpChoice", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeConfirmTurnOnPopUpTitle: String {
            return LocalizedString(key: "tCE", originalKey: "Lark_Security_LeanModeConfirmTurnOnPopUpTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeConfirmTurnOnPopUpTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tCE", originalKey: "Lark_Security_LeanModeConfirmTurnOnPopUpTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonRemindLater: String {
            return LocalizedString(key: "9ew", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonRemindLater")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonRemindLater(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9ew", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonRemindLater", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonSetNow: String {
            return LocalizedString(key: "5sU", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonSetNow")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonSetNow(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "5sU", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonSetNow", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpContentMobile: String {
            return LocalizedString(key: "7+E", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpContentMobile")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpContentMobile(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7+E", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpContentMobile", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpTitle: String {
            return LocalizedString(key: "Uxg", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Uxg", originalKey: "Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePopUpGeneralAckButton: String {
            return LocalizedString(key: "L3o", originalKey: "Lark_Security_LeanModePopUpGeneralAckButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePopUpGeneralAckButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "L3o", originalKey: "Lark_Security_LeanModePopUpGeneralAckButton", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePopUpGeneralButtonConfirm: String {
            return LocalizedString(key: "2D8", originalKey: "Lark_Security_LeanModePopUpGeneralButtonConfirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePopUpGeneralButtonConfirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2D8", originalKey: "Lark_Security_LeanModePopUpGeneralButtonConfirm", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModePopUpGeneralTitle: String {
            return LocalizedString(key: "iRw", originalKey: "Lark_Security_LeanModePopUpGeneralTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModePopUpGeneralTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iRw", originalKey: "Lark_Security_LeanModePopUpGeneralTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeSomethingWentWrongGeneralToast: String {
            return LocalizedString(key: "bfM", originalKey: "Lark_Security_LeanModeSomethingWentWrongGeneralToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeSomethingWentWrongGeneralToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bfM", originalKey: "Lark_Security_LeanModeSomethingWentWrongGeneralToast", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeSwitchModePrepareLoading: String {
            return LocalizedString(key: "LTM", originalKey: "Lark_Security_LeanModeSwitchModePrepareLoading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeSwitchModePrepareLoading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "LTM", originalKey: "Lark_Security_LeanModeSwitchModePrepareLoading", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpButton: String {
            return LocalizedString(key: "ZMU", originalKey: "Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZMU", originalKey: "Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpButton", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpContent: String {
            return LocalizedString(key: "Ts8", originalKey: "Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ts8", originalKey: "Lark_Security_LeanModeSwitchTenantIdentityRestartPopUpContent", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffIdentityVerificationPageButton: String {
            return LocalizedString(key: "wPg", originalKey: "Lark_Security_LeanModeTurnOffIdentityVerificationPageButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffIdentityVerificationPageButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "wPg", originalKey: "Lark_Security_LeanModeTurnOffIdentityVerificationPageButton", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffIdentityVerificationPageContent: String {
            return LocalizedString(key: "n6o", originalKey: "Lark_Security_LeanModeTurnOffIdentityVerificationPageContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffIdentityVerificationPageContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "n6o", originalKey: "Lark_Security_LeanModeTurnOffIdentityVerificationPageContent", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffIdentityVerificationPageTitle: String {
            return LocalizedString(key: "bas", originalKey: "Lark_Security_LeanModeTurnOffIdentityVerificationPageTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffIdentityVerificationPageTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bas", originalKey: "Lark_Security_LeanModeTurnOffIdentityVerificationPageTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffNoAccessContent: String {
            return LocalizedString(key: "YbY", originalKey: "Lark_Security_LeanModeTurnOffNoAccessContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffNoAccessContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YbY", originalKey: "Lark_Security_LeanModeTurnOffNoAccessContent", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffOtherDeviceButtonForAll: String {
            return LocalizedString(key: "/JE", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceButtonForAll")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffOtherDeviceButtonForAll(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/JE", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceButtonForAll", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffOtherDeviceButtonJustThis: String {
            return LocalizedString(key: "hHg", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceButtonJustThis")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffOtherDeviceButtonJustThis(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "hHg", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceButtonJustThis", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffOtherDeviceContent: String {
            return LocalizedString(key: "8kE", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffOtherDeviceContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "8kE", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceContent", lang: __lang)
        }
        @inlinable
        static var Lark_Security_LeanModeTurnOffOtherDeviceTitle: String {
            return LocalizedString(key: "vzA", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Security_LeanModeTurnOffOtherDeviceTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vzA", originalKey: "Lark_Security_LeanModeTurnOffOtherDeviceTitle", lang: __lang)
        }
    }
}
// swiftlint:enable all
