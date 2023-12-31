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
"Lark_IM_Report_SelectChatHistoryAndTryAgain_Toast":{
"hash":"qCE",
"#vars":0
},
"Lark_Invitation_AddMembersContactsPermission":{
"hash":"IBE",
"#vars":0
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_Hint":{
"hash":"4L8",
"#vars":0
},
"Lark_Legacy_JssdkCopySuccess":{
"hash":"NFE",
"#vars":0
},
"Lark_UserGrowth_InviteMemberImportContactsCancel":{
"hash":"+0U",
"#vars":0
},
"Lark_UserGrowth_InviteMemberImportContactsSettings":{
"hash":"o4g",
"#vars":0
},
"Lark_UserGrowth_InviteMemberImportContactsTitle":{
"hash":"UGU",
"#vars":0
},
"OpenPlatform_AppCenter_Cancel":{
"hash":"CfA",
"#vars":0
},
"OpenPlatform_AppCenter_CannotIdentifyBarcode":{
"hash":"avE",
"#vars":0
},
"OpenPlatform_AppCenter_Confirm":{
"hash":"6AA",
"#vars":0
},
"OpenPlatform_AppCenter_EnterBarcode":{
"hash":"2IA",
"#vars":0
},
"OpenPlatform_AppCenter_OpenWithAnotherApp":{
"hash":"O80",
"#vars":0
},
"OpenPlatform_AppCenter_PleaseEnterBarcode":{
"hash":"4cE",
"#vars":0
}
},
"name":"JsSDK",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.JsSDKAutoBundle, moduleName: "JsSDK", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.JsSDKAutoBundle, moduleName: "JsSDK", lang: lang) ?? key
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
    final class JsSDK {
        @inlinable
        static var Lark_IM_Report_SelectChatHistoryAndTryAgain_Toast: String {
            return LocalizedString(key: "qCE", originalKey: "Lark_IM_Report_SelectChatHistoryAndTryAgain_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_Report_SelectChatHistoryAndTryAgain_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qCE", originalKey: "Lark_IM_Report_SelectChatHistoryAndTryAgain_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_AddMembersContactsPermission: String {
            return LocalizedString(key: "IBE", originalKey: "Lark_Invitation_AddMembersContactsPermission")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_AddMembersContactsPermission(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "IBE", originalKey: "Lark_Invitation_AddMembersContactsPermission", lang: __lang)
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
        static var Lark_Legacy_Hint: String {
            return LocalizedString(key: "4L8", originalKey: "Lark_Legacy_Hint")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Hint(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4L8", originalKey: "Lark_Legacy_Hint", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_JssdkCopySuccess: String {
            return LocalizedString(key: "NFE", originalKey: "Lark_Legacy_JssdkCopySuccess")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_JssdkCopySuccess(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NFE", originalKey: "Lark_Legacy_JssdkCopySuccess", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InviteMemberImportContactsCancel: String {
            return LocalizedString(key: "+0U", originalKey: "Lark_UserGrowth_InviteMemberImportContactsCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InviteMemberImportContactsCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "+0U", originalKey: "Lark_UserGrowth_InviteMemberImportContactsCancel", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InviteMemberImportContactsSettings: String {
            return LocalizedString(key: "o4g", originalKey: "Lark_UserGrowth_InviteMemberImportContactsSettings")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InviteMemberImportContactsSettings(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "o4g", originalKey: "Lark_UserGrowth_InviteMemberImportContactsSettings", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InviteMemberImportContactsTitle: String {
            return LocalizedString(key: "UGU", originalKey: "Lark_UserGrowth_InviteMemberImportContactsTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InviteMemberImportContactsTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "UGU", originalKey: "Lark_UserGrowth_InviteMemberImportContactsTitle", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_Cancel: String {
            return LocalizedString(key: "CfA", originalKey: "OpenPlatform_AppCenter_Cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_Cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "CfA", originalKey: "OpenPlatform_AppCenter_Cancel", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_CannotIdentifyBarcode: String {
            return LocalizedString(key: "avE", originalKey: "OpenPlatform_AppCenter_CannotIdentifyBarcode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_CannotIdentifyBarcode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "avE", originalKey: "OpenPlatform_AppCenter_CannotIdentifyBarcode", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_Confirm: String {
            return LocalizedString(key: "6AA", originalKey: "OpenPlatform_AppCenter_Confirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_Confirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6AA", originalKey: "OpenPlatform_AppCenter_Confirm", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_EnterBarcode: String {
            return LocalizedString(key: "2IA", originalKey: "OpenPlatform_AppCenter_EnterBarcode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_EnterBarcode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2IA", originalKey: "OpenPlatform_AppCenter_EnterBarcode", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_OpenWithAnotherApp: String {
            return LocalizedString(key: "O80", originalKey: "OpenPlatform_AppCenter_OpenWithAnotherApp")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_OpenWithAnotherApp(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "O80", originalKey: "OpenPlatform_AppCenter_OpenWithAnotherApp", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_PleaseEnterBarcode: String {
            return LocalizedString(key: "4cE", originalKey: "OpenPlatform_AppCenter_PleaseEnterBarcode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_PleaseEnterBarcode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4cE", originalKey: "OpenPlatform_AppCenter_PleaseEnterBarcode", lang: __lang)
        }
    }
}
// swiftlint:enable all
