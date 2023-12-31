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
"Lark_Core_UnableShareToQQ_Toast":{
"hash":"Kxk",
"#vars":0
},
"Lark_Core_UnableShareToWechat_Toast":{
"hash":"Vn4",
"#vars":0
},
"Lark_Core_UnableShareToWeibo_Toast":{
"hash":"/i4",
"#vars":0
},
"Lark_Invitation_InviteViaWeChat_General_Title":{
"hash":"Wbo",
"#vars":0
},
"Lark_Invitation_SharePYQ":{
"hash":"n5Q",
"#vars":0
},
"Lark_Invitation_ShareViaQQ_ImageCreatedAndSaved_button":{
"hash":"Zk4",
"#vars":0
},
"Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved":{
"hash":"9uA",
"#vars":0
},
"Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved_button":{
"hash":"Iig",
"#vars":0
},
"Lark_Invitation_ShareViaWeibo_ImageCreatedAndSaved_button":{
"hash":"iQ0",
"#vars":0
},
"Lark_Invitation_TeamCodeClose":{
"hash":"41w",
"#vars":0
},
"Lark_Legacy_AssetBrowserPhotoDenied":{
"hash":"snY",
"#vars":0
},
"Lark_Legacy_CancelOpen":{
"hash":"cs4",
"#vars":0
},
"Lark_Legacy_QrCodeSave":{
"hash":"Ln4",
"#vars":0
},
"Lark_UD_SharePanelCopyLink":{
"hash":"xEQ",
"#vars":0
},
"Lark_UD_SharePanelSave":{
"hash":"jFM",
"#vars":0
},
"Lark_UD_SharePanelSaveFailRetryToast":{
"hash":"hRY",
"#vars":0
},
"Lark_UD_SharePanelShareImage":{
"hash":"VSM",
"#vars":0
},
"Lark_UD_SharePanelShareTitle":{
"hash":"k9g",
"#vars":0
},
"Lark_UserGrowth_InvitePeopleContactsShareNotInstalled":{
"hash":"gog",
"#vars":0
},
"Lark_UserGrowth_InvitePeopleContactsShareTo":{
"hash":"BWM",
"#vars":0
},
"Lark_UserGrowth_InvitePeopleContactsShareToCopy":{
"hash":"/s8",
"#vars":0
},
"Lark_UserGrowth_InvitePeopleContactsShareToMore":{
"hash":"v80",
"#vars":0
},
"Lark_UserGrowth_TitleQQ":{
"hash":"s6c",
"#vars":0
},
"Lark_UserGrowth_TitleWechat":{
"hash":"HtU",
"#vars":0
},
"Lark_UserGrowth_TitleWeibo":{
"hash":"s/s",
"#vars":0
}
},
"name":"LarkSnsShare",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkSnsShareAutoBundle, moduleName: "LarkSnsShare", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkSnsShareAutoBundle, moduleName: "LarkSnsShare", lang: lang) ?? key
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
    final class LarkSnsShare {
        @inlinable
        static var Lark_Core_UnableShareToQQ_Toast: String {
            return LocalizedString(key: "Kxk", originalKey: "Lark_Core_UnableShareToQQ_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_UnableShareToQQ_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Kxk", originalKey: "Lark_Core_UnableShareToQQ_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_Core_UnableShareToWechat_Toast: String {
            return LocalizedString(key: "Vn4", originalKey: "Lark_Core_UnableShareToWechat_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_UnableShareToWechat_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Vn4", originalKey: "Lark_Core_UnableShareToWechat_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_Core_UnableShareToWeibo_Toast: String {
            return LocalizedString(key: "/i4", originalKey: "Lark_Core_UnableShareToWeibo_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_UnableShareToWeibo_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/i4", originalKey: "Lark_Core_UnableShareToWeibo_Toast", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_InviteViaWeChat_General_Title: String {
            return LocalizedString(key: "Wbo", originalKey: "Lark_Invitation_InviteViaWeChat_General_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_InviteViaWeChat_General_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Wbo", originalKey: "Lark_Invitation_InviteViaWeChat_General_Title", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_SharePYQ: String {
            return LocalizedString(key: "n5Q", originalKey: "Lark_Invitation_SharePYQ")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_SharePYQ(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "n5Q", originalKey: "Lark_Invitation_SharePYQ", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_ShareViaQQ_ImageCreatedAndSaved_button: String {
            return LocalizedString(key: "Zk4", originalKey: "Lark_Invitation_ShareViaQQ_ImageCreatedAndSaved_button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_ShareViaQQ_ImageCreatedAndSaved_button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Zk4", originalKey: "Lark_Invitation_ShareViaQQ_ImageCreatedAndSaved_button", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved: String {
            return LocalizedString(key: "9uA", originalKey: "Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9uA", originalKey: "Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved_button: String {
            return LocalizedString(key: "Iig", originalKey: "Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved_button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved_button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Iig", originalKey: "Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved_button", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_ShareViaWeibo_ImageCreatedAndSaved_button: String {
            return LocalizedString(key: "iQ0", originalKey: "Lark_Invitation_ShareViaWeibo_ImageCreatedAndSaved_button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_ShareViaWeibo_ImageCreatedAndSaved_button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iQ0", originalKey: "Lark_Invitation_ShareViaWeibo_ImageCreatedAndSaved_button", lang: __lang)
        }
        @inlinable
        static var Lark_Invitation_TeamCodeClose: String {
            return LocalizedString(key: "41w", originalKey: "Lark_Invitation_TeamCodeClose")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Invitation_TeamCodeClose(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "41w", originalKey: "Lark_Invitation_TeamCodeClose", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_AssetBrowserPhotoDenied: String {
            return LocalizedString(key: "snY", originalKey: "Lark_Legacy_AssetBrowserPhotoDenied")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_AssetBrowserPhotoDenied(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "snY", originalKey: "Lark_Legacy_AssetBrowserPhotoDenied", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_CancelOpen: String {
            return LocalizedString(key: "cs4", originalKey: "Lark_Legacy_CancelOpen")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_CancelOpen(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "cs4", originalKey: "Lark_Legacy_CancelOpen", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_QrCodeSave: String {
            return LocalizedString(key: "Ln4", originalKey: "Lark_Legacy_QrCodeSave")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_QrCodeSave(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ln4", originalKey: "Lark_Legacy_QrCodeSave", lang: __lang)
        }
        @inlinable
        static var Lark_UD_SharePanelCopyLink: String {
            return LocalizedString(key: "xEQ", originalKey: "Lark_UD_SharePanelCopyLink")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UD_SharePanelCopyLink(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "xEQ", originalKey: "Lark_UD_SharePanelCopyLink", lang: __lang)
        }
        @inlinable
        static var Lark_UD_SharePanelSave: String {
            return LocalizedString(key: "jFM", originalKey: "Lark_UD_SharePanelSave")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UD_SharePanelSave(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "jFM", originalKey: "Lark_UD_SharePanelSave", lang: __lang)
        }
        @inlinable
        static var Lark_UD_SharePanelSaveFailRetryToast: String {
            return LocalizedString(key: "hRY", originalKey: "Lark_UD_SharePanelSaveFailRetryToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UD_SharePanelSaveFailRetryToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "hRY", originalKey: "Lark_UD_SharePanelSaveFailRetryToast", lang: __lang)
        }
        @inlinable
        static var Lark_UD_SharePanelShareImage: String {
            return LocalizedString(key: "VSM", originalKey: "Lark_UD_SharePanelShareImage")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UD_SharePanelShareImage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "VSM", originalKey: "Lark_UD_SharePanelShareImage", lang: __lang)
        }
        @inlinable
        static var Lark_UD_SharePanelShareTitle: String {
            return LocalizedString(key: "k9g", originalKey: "Lark_UD_SharePanelShareTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UD_SharePanelShareTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "k9g", originalKey: "Lark_UD_SharePanelShareTitle", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InvitePeopleContactsShareNotInstalled: String {
            return LocalizedString(key: "gog", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareNotInstalled")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InvitePeopleContactsShareNotInstalled(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "gog", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareNotInstalled", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InvitePeopleContactsShareTo: String {
            return LocalizedString(key: "BWM", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareTo")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InvitePeopleContactsShareTo(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "BWM", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareTo", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InvitePeopleContactsShareToCopy: String {
            return LocalizedString(key: "/s8", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareToCopy")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InvitePeopleContactsShareToCopy(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/s8", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareToCopy", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_InvitePeopleContactsShareToMore: String {
            return LocalizedString(key: "v80", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareToMore")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_InvitePeopleContactsShareToMore(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "v80", originalKey: "Lark_UserGrowth_InvitePeopleContactsShareToMore", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_TitleQQ: String {
            return LocalizedString(key: "s6c", originalKey: "Lark_UserGrowth_TitleQQ")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_TitleQQ(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "s6c", originalKey: "Lark_UserGrowth_TitleQQ", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_TitleWechat: String {
            return LocalizedString(key: "HtU", originalKey: "Lark_UserGrowth_TitleWechat")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_TitleWechat(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HtU", originalKey: "Lark_UserGrowth_TitleWechat", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_TitleWeibo: String {
            return LocalizedString(key: "s/s", originalKey: "Lark_UserGrowth_TitleWeibo")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_TitleWeibo(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "s/s", originalKey: "Lark_UserGrowth_TitleWeibo", lang: __lang)
        }
    }
}
// swiftlint:enable all
