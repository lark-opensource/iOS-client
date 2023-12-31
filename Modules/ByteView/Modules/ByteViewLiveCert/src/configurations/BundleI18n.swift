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
"View_G_AuthenticationFailed":{
"hash":"gqY",
"#vars":0
},
"View_G_AuthenticationResultsNoMatch":{
"hash":"AjY",
"#vars":0
},
"View_G_AuthenticationRetry":{
"hash":"+zU",
"#vars":0
},
"View_G_AuthenticationSuccess":{
"hash":"r5A",
"#vars":0
},
"View_G_CancelButton":{
"hash":"zHo",
"#vars":0
},
"View_G_ConfirmButton":{
"hash":"mnY",
"#vars":0
},
"View_G_EnterIdNumber":{
"hash":"4oM",
"#vars":0
},
"View_G_EnterRealName":{
"hash":"inU",
"#vars":0
},
"View_G_FacialRecognitionInfo":{
"hash":"0/Y",
"#vars":0
},
"View_G_FacialRecognitionSelf":{
"hash":"r0Y",
"#vars":1,
"normal_vars":["name"]
},
"View_G_NextStep":{
"hash":"jcg",
"#vars":0
},
"View_G_OkButton":{
"hash":"B1I",
"#vars":0
},
"View_G_Quit":{
"hash":"pgY",
"#vars":0
},
"View_G_RealNameAuthentication":{
"hash":"Udc",
"#vars":0
},
"View_G_RealNameAuthenticationInfo":{
"hash":"aHQ",
"#vars":0
},
"View_G_SomethingWentWrong":{
"hash":"iXI",
"#vars":0
},
"View_G_StartFacialRecognition":{
"hash":"KV4",
"#vars":0
},
"View_VM_NotificationDefault":{
"hash":"Pok",
"#vars":0
}
},
"name":"ByteViewLiveCert",
"short_key":true,
"config":{
"positional-args":true,
"use-native":true,
"mapping":{
"ms":"ms-MY",
"id":"id-ID",
"de":"de-DE",
"en":"en-US",
"es":"es-ES",
"fr":"fr-FR",
"it":"it-IT",
"pt":"pt-BR",
"vi":"vi-VN",
"ru":"ru-RU",
"hi":"hi-IN",
"th":"th-TH",
"ko":"ko-KR",
"zh":"zh-CN",
"ja":"ja-JP"
}
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.ByteViewLiveCertAutoBundle, moduleName: "ByteViewLiveCert", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.ByteViewLiveCertAutoBundle, moduleName: "ByteViewLiveCert", lang: lang) ?? key
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
    final class ByteViewLiveCert {
        @inlinable
        static var View_G_AuthenticationFailed: String {
            return LocalizedString(key: "gqY", originalKey: "View_G_AuthenticationFailed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_AuthenticationFailed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "gqY", originalKey: "View_G_AuthenticationFailed", lang: __lang)
        }
        @inlinable
        static var View_G_AuthenticationResultsNoMatch: String {
            return LocalizedString(key: "AjY", originalKey: "View_G_AuthenticationResultsNoMatch")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_AuthenticationResultsNoMatch(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "AjY", originalKey: "View_G_AuthenticationResultsNoMatch", lang: __lang)
        }
        @inlinable
        static var View_G_AuthenticationRetry: String {
            return LocalizedString(key: "+zU", originalKey: "View_G_AuthenticationRetry")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_AuthenticationRetry(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "+zU", originalKey: "View_G_AuthenticationRetry", lang: __lang)
        }
        @inlinable
        static var View_G_AuthenticationSuccess: String {
            return LocalizedString(key: "r5A", originalKey: "View_G_AuthenticationSuccess")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_AuthenticationSuccess(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "r5A", originalKey: "View_G_AuthenticationSuccess", lang: __lang)
        }
        @inlinable
        static var View_G_CancelButton: String {
            return LocalizedString(key: "zHo", originalKey: "View_G_CancelButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_CancelButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zHo", originalKey: "View_G_CancelButton", lang: __lang)
        }
        @inlinable
        static var View_G_ConfirmButton: String {
            return LocalizedString(key: "mnY", originalKey: "View_G_ConfirmButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_ConfirmButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "mnY", originalKey: "View_G_ConfirmButton", lang: __lang)
        }
        @inlinable
        static var View_G_EnterIdNumber: String {
            return LocalizedString(key: "4oM", originalKey: "View_G_EnterIdNumber")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_EnterIdNumber(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4oM", originalKey: "View_G_EnterIdNumber", lang: __lang)
        }
        @inlinable
        static var View_G_EnterRealName: String {
            return LocalizedString(key: "inU", originalKey: "View_G_EnterRealName")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_EnterRealName(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "inU", originalKey: "View_G_EnterRealName", lang: __lang)
        }
        @inlinable
        static var View_G_FacialRecognitionInfo: String {
            return LocalizedString(key: "0/Y", originalKey: "View_G_FacialRecognitionInfo")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_FacialRecognitionInfo(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "0/Y", originalKey: "View_G_FacialRecognitionInfo", lang: __lang)
        }
        @inlinable
        static var __View_G_FacialRecognitionSelf: String {
            return LocalizedString(key: "r0Y", originalKey: "View_G_FacialRecognitionSelf")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_FacialRecognitionSelf(_ name: Any, lang __lang: Lang? = nil) -> String {
          return View_G_FacialRecognitionSelf(name: `name`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func View_G_FacialRecognitionSelf(name: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "r0Y", originalKey: "View_G_FacialRecognitionSelf", lang: __lang)
            template = template.replacingOccurrences(of: "{{name}}", with: "\(`name`)")
            return template
        }
        @inlinable
        static var View_G_NextStep: String {
            return LocalizedString(key: "jcg", originalKey: "View_G_NextStep")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_NextStep(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "jcg", originalKey: "View_G_NextStep", lang: __lang)
        }
        @inlinable
        static var View_G_OkButton: String {
            return LocalizedString(key: "B1I", originalKey: "View_G_OkButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_OkButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "B1I", originalKey: "View_G_OkButton", lang: __lang)
        }
        @inlinable
        static var View_G_Quit: String {
            return LocalizedString(key: "pgY", originalKey: "View_G_Quit")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_Quit(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "pgY", originalKey: "View_G_Quit", lang: __lang)
        }
        @inlinable
        static var View_G_RealNameAuthentication: String {
            return LocalizedString(key: "Udc", originalKey: "View_G_RealNameAuthentication")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_RealNameAuthentication(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Udc", originalKey: "View_G_RealNameAuthentication", lang: __lang)
        }
        @inlinable
        static var View_G_RealNameAuthenticationInfo: String {
            return LocalizedString(key: "aHQ", originalKey: "View_G_RealNameAuthenticationInfo")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_RealNameAuthenticationInfo(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "aHQ", originalKey: "View_G_RealNameAuthenticationInfo", lang: __lang)
        }
        @inlinable
        static var View_G_SomethingWentWrong: String {
            return LocalizedString(key: "iXI", originalKey: "View_G_SomethingWentWrong")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_SomethingWentWrong(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iXI", originalKey: "View_G_SomethingWentWrong", lang: __lang)
        }
        @inlinable
        static var View_G_StartFacialRecognition: String {
            return LocalizedString(key: "KV4", originalKey: "View_G_StartFacialRecognition")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_G_StartFacialRecognition(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "KV4", originalKey: "View_G_StartFacialRecognition", lang: __lang)
        }
        @inlinable
        static var View_VM_NotificationDefault: String {
            return LocalizedString(key: "Pok", originalKey: "View_VM_NotificationDefault")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func View_VM_NotificationDefault(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Pok", originalKey: "View_VM_NotificationDefault", lang: __lang)
        }
    }
}
// swiftlint:enable all
