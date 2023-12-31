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
"Lark_MessageNotifications_FromOtherAccounts_ExitStay_Button":{
"hash":"Ul4",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_Exit_Button":{
"hash":"AlQ",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_Exit_Desc":{
"hash":"2h0",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_MessageSent_Toast":{
"hash":"HXY",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Cancel_Button":{
"hash":"hF0",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Switch_Button":{
"hash":"iyo",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_SwitchAccountToView_Text":{
"hash":"xUg",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_SwitchAccount_Button":{
"hash":"PJU",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_SwitchToViewMsgPopUp_Title":{
"hash":"DKo",
"#vars":0
},
"Lark_MessageNotifications_FromOtherAccounts_UnableTosend_Toast":{
"hash":"wJs",
"#vars":0
}
},
"name":"LarkNotificationAssembly",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkNotificationAssemblyAutoBundle, moduleName: "LarkNotificationAssembly", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkNotificationAssemblyAutoBundle, moduleName: "LarkNotificationAssembly", lang: lang) ?? key
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
    final class LarkNotificationAssembly {
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_ExitStay_Button: String {
            return LocalizedString(key: "Ul4", originalKey: "Lark_MessageNotifications_FromOtherAccounts_ExitStay_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_ExitStay_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ul4", originalKey: "Lark_MessageNotifications_FromOtherAccounts_ExitStay_Button", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_Exit_Button: String {
            return LocalizedString(key: "AlQ", originalKey: "Lark_MessageNotifications_FromOtherAccounts_Exit_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_Exit_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "AlQ", originalKey: "Lark_MessageNotifications_FromOtherAccounts_Exit_Button", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_Exit_Desc: String {
            return LocalizedString(key: "2h0", originalKey: "Lark_MessageNotifications_FromOtherAccounts_Exit_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_Exit_Desc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2h0", originalKey: "Lark_MessageNotifications_FromOtherAccounts_Exit_Desc", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_MessageSent_Toast: String {
            return LocalizedString(key: "HXY", originalKey: "Lark_MessageNotifications_FromOtherAccounts_MessageSent_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_MessageSent_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HXY", originalKey: "Lark_MessageNotifications_FromOtherAccounts_MessageSent_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Cancel_Button: String {
            return LocalizedString(key: "hF0", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Cancel_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Cancel_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "hF0", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Cancel_Button", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Switch_Button: String {
            return LocalizedString(key: "iyo", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Switch_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Switch_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iyo", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccountPopUp_Switch_Button", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_SwitchAccountToView_Text: String {
            return LocalizedString(key: "xUg", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccountToView_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_SwitchAccountToView_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "xUg", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccountToView_Text", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_SwitchAccount_Button: String {
            return LocalizedString(key: "PJU", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccount_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_SwitchAccount_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PJU", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchAccount_Button", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_SwitchToViewMsgPopUp_Title: String {
            return LocalizedString(key: "DKo", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchToViewMsgPopUp_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_SwitchToViewMsgPopUp_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "DKo", originalKey: "Lark_MessageNotifications_FromOtherAccounts_SwitchToViewMsgPopUp_Title", lang: __lang)
        }
        @inlinable
        static var Lark_MessageNotifications_FromOtherAccounts_UnableTosend_Toast: String {
            return LocalizedString(key: "wJs", originalKey: "Lark_MessageNotifications_FromOtherAccounts_UnableTosend_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_MessageNotifications_FromOtherAccounts_UnableTosend_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "wJs", originalKey: "Lark_MessageNotifications_FromOtherAccounts_UnableTosend_Toast", lang: __lang)
        }
    }
}
// swiftlint:enable all
