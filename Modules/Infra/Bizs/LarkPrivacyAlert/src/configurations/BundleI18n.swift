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
"Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerButton":{
"hash":"8VA",
"#vars":0
},
"Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerPrivacyPolicy":{
"hash":"ot4",
"#vars":0
},
"Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText":{
"hash":"oFM",
"#vars":2,
"normal_vars":["UserAgreement","PrivacyPolicy"]
},
"Lark_Core_AcceptServiceTermPrivacyPolicy_UserAgreement":{
"hash":"oLE",
"#vars":0
},
"Lark_Core_RejectServiceTermPrivacyPolicy_AndQuit_Button":{
"hash":"LwE",
"#vars":0
},
"Lark_Guide_V3_PrivacyPolicy":{
"hash":"UGQ",
"#vars":0
},
"Lark_Guide_V3_serviceterms":{
"hash":"NBE",
"#vars":0
},
"Lark_Login_AgreeToUse":{
"hash":"c3c",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Login_ServiceTermPrivacyPolicy":{
"hash":"tJE",
"#vars":2,
"normal_vars":["serviceTerm","privacy"]
},
"Lark_Login_V3_Lark_PrivacyButtonagree":{
"hash":"HvA",
"#vars":0
},
"Lark_Login_V3_Lark_PrivacyButtondisagree":{
"hash":"pZw",
"#vars":0
},
"Lark_Login_V3_Lark_PrivacyNotice":{
"hash":"ZT8",
"#vars":0
},
"Lark_Login_V3_Lark_PrivacyNoticeTitle":{
"hash":"qIs",
"#vars":0
},
"Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_AcceptButton":{
"hash":"3WA",
"#vars":0
},
"Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_DeclineButton":{
"hash":"F7E",
"#vars":0
},
"Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText":{
"hash":"oyw",
"#vars":3,
"normal_vars":["serviceTerm","privacy","APP_DISPLAY_NAME"]
},
"Lark_PrivacyPolicy_WhatsFeishu_PopupText":{
"hash":"f4Q",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
}
},
"name":"LarkPrivacyAlert",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkPrivacyAlertAutoBundle, moduleName: "LarkPrivacyAlert", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkPrivacyAlertAutoBundle, moduleName: "LarkPrivacyAlert", lang: lang) ?? key
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
    final class LarkPrivacyAlert {
        @inlinable
        static var Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerButton: String {
            return LocalizedString(key: "8VA", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "8VA", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerButton", lang: __lang)
        }
        @inlinable
        static var Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerPrivacyPolicy: String {
            return LocalizedString(key: "ot4", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerPrivacyPolicy")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerPrivacyPolicy(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ot4", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerPrivacyPolicy", lang: __lang)
        }
        @inlinable
        static var __Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText: String {
            return LocalizedString(key: "oFM", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText(_ UserAgreement: Any, _ PrivacyPolicy: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText(UserAgreement: `UserAgreement`, PrivacyPolicy: `PrivacyPolicy`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText(UserAgreement: Any, PrivacyPolicy: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "oFM", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText", lang: __lang)
            template = template.replacingOccurrences(of: "{{UserAgreement}}", with: "\(`UserAgreement`)")
            template = template.replacingOccurrences(of: "{{PrivacyPolicy}}", with: "\(`PrivacyPolicy`)")
            return template
        }
        @inlinable
        static var Lark_Core_AcceptServiceTermPrivacyPolicy_UserAgreement: String {
            return LocalizedString(key: "oLE", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_UserAgreement")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_AcceptServiceTermPrivacyPolicy_UserAgreement(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "oLE", originalKey: "Lark_Core_AcceptServiceTermPrivacyPolicy_UserAgreement", lang: __lang)
        }
        @inlinable
        static var Lark_Core_RejectServiceTermPrivacyPolicy_AndQuit_Button: String {
            return LocalizedString(key: "LwE", originalKey: "Lark_Core_RejectServiceTermPrivacyPolicy_AndQuit_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_RejectServiceTermPrivacyPolicy_AndQuit_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "LwE", originalKey: "Lark_Core_RejectServiceTermPrivacyPolicy_AndQuit_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Guide_V3_PrivacyPolicy: String {
            return LocalizedString(key: "UGQ", originalKey: "Lark_Guide_V3_PrivacyPolicy")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Guide_V3_PrivacyPolicy(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "UGQ", originalKey: "Lark_Guide_V3_PrivacyPolicy", lang: __lang)
        }
        @inlinable
        static var Lark_Guide_V3_serviceterms: String {
            return LocalizedString(key: "NBE", originalKey: "Lark_Guide_V3_serviceterms")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Guide_V3_serviceterms(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NBE", originalKey: "Lark_Guide_V3_serviceterms", lang: __lang)
        }
        @inlinable
        static var __Lark_Login_AgreeToUse: String {
            return LocalizedString(key: "c3c", originalKey: "Lark_Login_AgreeToUse")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Login_AgreeToUse(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "c3c", originalKey: "Lark_Login_AgreeToUse", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var __Lark_Login_ServiceTermPrivacyPolicy: String {
            return LocalizedString(key: "tJE", originalKey: "Lark_Login_ServiceTermPrivacyPolicy")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_ServiceTermPrivacyPolicy(_ serviceTerm: Any, _ privacy: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Login_ServiceTermPrivacyPolicy(serviceTerm: `serviceTerm`, privacy: `privacy`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Login_ServiceTermPrivacyPolicy(serviceTerm: Any, privacy: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "tJE", originalKey: "Lark_Login_ServiceTermPrivacyPolicy", lang: __lang)
            template = template.replacingOccurrences(of: "{{serviceTerm}}", with: "\(`serviceTerm`)")
            template = template.replacingOccurrences(of: "{{privacy}}", with: "\(`privacy`)")
            return template
        }
        @inlinable
        static var Lark_Login_V3_Lark_PrivacyButtonagree: String {
            return LocalizedString(key: "HvA", originalKey: "Lark_Login_V3_Lark_PrivacyButtonagree")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_V3_Lark_PrivacyButtonagree(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HvA", originalKey: "Lark_Login_V3_Lark_PrivacyButtonagree", lang: __lang)
        }
        @inlinable
        static var Lark_Login_V3_Lark_PrivacyButtondisagree: String {
            return LocalizedString(key: "pZw", originalKey: "Lark_Login_V3_Lark_PrivacyButtondisagree")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_V3_Lark_PrivacyButtondisagree(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "pZw", originalKey: "Lark_Login_V3_Lark_PrivacyButtondisagree", lang: __lang)
        }
        @inlinable
        static var Lark_Login_V3_Lark_PrivacyNotice: String {
            return LocalizedString(key: "ZT8", originalKey: "Lark_Login_V3_Lark_PrivacyNotice")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_V3_Lark_PrivacyNotice(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZT8", originalKey: "Lark_Login_V3_Lark_PrivacyNotice", lang: __lang)
        }
        @inlinable
        static var Lark_Login_V3_Lark_PrivacyNoticeTitle: String {
            return LocalizedString(key: "qIs", originalKey: "Lark_Login_V3_Lark_PrivacyNoticeTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_V3_Lark_PrivacyNoticeTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qIs", originalKey: "Lark_Login_V3_Lark_PrivacyNoticeTitle", lang: __lang)
        }
        @inlinable
        static var Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_AcceptButton: String {
            return LocalizedString(key: "3WA", originalKey: "Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_AcceptButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_AcceptButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "3WA", originalKey: "Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_AcceptButton", lang: __lang)
        }
        @inlinable
        static var Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_DeclineButton: String {
            return LocalizedString(key: "F7E", originalKey: "Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_DeclineButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_DeclineButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "F7E", originalKey: "Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_DeclineButton", lang: __lang)
        }
        @inlinable
        static var __Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText: String {
            return LocalizedString(key: "oyw", originalKey: "Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText(_ serviceTerm: Any, _ privacy: Any, lang __lang: Lang? = nil) -> String {
          return Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText(serviceTerm: `serviceTerm`, privacy: `privacy`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText(serviceTerm: Any, privacy: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "oyw", originalKey: "Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText", lang: __lang)
            template = template.replacingOccurrences(of: "{{serviceTerm}}", with: "\(`serviceTerm`)")
            template = template.replacingOccurrences(of: "{{privacy}}", with: "\(`privacy`)")
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var __Lark_PrivacyPolicy_WhatsFeishu_PopupText: String {
            return LocalizedString(key: "f4Q", originalKey: "Lark_PrivacyPolicy_WhatsFeishu_PopupText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_PrivacyPolicy_WhatsFeishu_PopupText(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "f4Q", originalKey: "Lark_PrivacyPolicy_WhatsFeishu_PopupText", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
    }
}
// swiftlint:enable all
