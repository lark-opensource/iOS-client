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
"Lark_AppCenter_H5AboutPageName":{
"hash":"lDU",
"#vars":0
},
"Lark_Legacy_JssdkCopySuccess":{
"hash":"NFE",
"#vars":0
},
"Lark_Legacy_Sure":{
"hash":"DrA",
"#vars":0
},
"Lark_Legacy_UnknownErr":{
"hash":"VAI",
"#vars":0
},
"Lark_Legacy_WebBrowseOpen":{
"hash":"NVg",
"#vars":0
},
"Lark_Legacy_WebCopyUri":{
"hash":"fBw",
"#vars":0
},
"Lark_Legacy_WebRefresh":{
"hash":"b5Y",
"#vars":0
},
"Lark_OpenPlatform_ParamMissingMsg":{
"hash":"qwY",
"#vars":1,
"normal_vars":["list"]
},
"Mail_FileCantShareOrOpenViaThirdPartyApp_Toast":{
"hash":"IBk",
"#vars":0
},
"OpenPlatform_AppActions_DisplayDomainDesc":{
"hash":"zz0",
"#vars":1,
"normal_vars":["root_domain"]
},
"OpenPlatform_AppActions_LoadingDesc":{
"hash":"04s",
"#vars":0
},
"OpenPlatform_AppActions_NetworkErrToast":{
"hash":"XxQ",
"#vars":0
},
"OpenPlatform_AppErrPage_PageLoadFailedErrDesc":{
"hash":"WqM",
"#vars":2,
"normal_vars":["errorDesc","errorCode"]
},
"OpenPlatform_AppRating_GoToRateLink":{
"hash":"Zg4",
"#vars":0
},
"OpenPlatform_AppRating_MyRatingTtl":{
"hash":"Fp8",
"#vars":0
},
"OpenPlatform_AppRating_NotRatedYet":{
"hash":"6P8",
"#vars":0
},
"OpenPlatform_GadgetErr_ClientVerTooLow":{
"hash":"PS4",
"#vars":0
},
"OpenPlatform_MobApp_AppPresents":{
"hash":"Loo",
"#vars":0
},
"OpenPlatform_MoreAppFcns_DevDisabledFcns":{
"hash":"eUM",
"#vars":0
},
"OpenPlatform_MoreAppFcns_UnableToCopyLink":{
"hash":"w94",
"#vars":0
},
"OpenPlatform_MoreAppFcns_UnableToOpenInBr":{
"hash":"lio",
"#vars":0
},
"OpenPlatform_Share_ParamWrongMsg":{
"hash":"BL0",
"#vars":1,
"normal_vars":["list"]
},
"OpenPlatform_WebView_OnlineDebug_Cancel":{
"hash":"V6s",
"#vars":0
},
"OpenPlatform_WebView_OnlineDebug_Close_Info":{
"hash":"YAE",
"#vars":0
},
"OpenPlatform_WebView_OnlineDebug_Confirm":{
"hash":"Ex8",
"#vars":0
},
"OpenPlatform_WebView_OnlineDebug_Open_Info":{
"hash":"lbg",
"#vars":0
},
"OpenPlatform_WebView_OnlineDebug_Panel":{
"hash":"TuA",
"#vars":0
},
"OpenPlatform_WebView_OnlineDebug_Tip":{
"hash":"zNw",
"#vars":0
},
"OpenPlatform__AppRating_UpdateRatingLink":{
"hash":"7wk",
"#vars":0
},
"WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging":{
"hash":"mmQ",
"#vars":0
},
"WebAppTool_WebAppRemoteDebug_UnableToDebugCurrentPage":{
"hash":"XVc",
"#vars":0
},
"loading_failed":{
"hash":"vfM",
"#vars":0
},
"url_illegal":{
"hash":"X0Y",
"#vars":0
}
},
"name":"EcosystemWeb",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.EcosystemWebAutoBundle, moduleName: "EcosystemWeb", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.EcosystemWebAutoBundle, moduleName: "EcosystemWeb", lang: lang) ?? key
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
    final class EcosystemWeb {
        @inlinable
        static var Lark_AppCenter_H5AboutPageName: String {
            return LocalizedString(key: "lDU", originalKey: "Lark_AppCenter_H5AboutPageName")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_AppCenter_H5AboutPageName(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lDU", originalKey: "Lark_AppCenter_H5AboutPageName", lang: __lang)
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
        static var Lark_Legacy_Sure: String {
            return LocalizedString(key: "DrA", originalKey: "Lark_Legacy_Sure")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Sure(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "DrA", originalKey: "Lark_Legacy_Sure", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_UnknownErr: String {
            return LocalizedString(key: "VAI", originalKey: "Lark_Legacy_UnknownErr")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_UnknownErr(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "VAI", originalKey: "Lark_Legacy_UnknownErr", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_WebBrowseOpen: String {
            return LocalizedString(key: "NVg", originalKey: "Lark_Legacy_WebBrowseOpen")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_WebBrowseOpen(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NVg", originalKey: "Lark_Legacy_WebBrowseOpen", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_WebCopyUri: String {
            return LocalizedString(key: "fBw", originalKey: "Lark_Legacy_WebCopyUri")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_WebCopyUri(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "fBw", originalKey: "Lark_Legacy_WebCopyUri", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_WebRefresh: String {
            return LocalizedString(key: "b5Y", originalKey: "Lark_Legacy_WebRefresh")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_WebRefresh(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "b5Y", originalKey: "Lark_Legacy_WebRefresh", lang: __lang)
        }
        @inlinable
        static var __Lark_OpenPlatform_ParamMissingMsg: String {
            return LocalizedString(key: "qwY", originalKey: "Lark_OpenPlatform_ParamMissingMsg")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_OpenPlatform_ParamMissingMsg(_ list: Any, lang __lang: Lang? = nil) -> String {
          return Lark_OpenPlatform_ParamMissingMsg(list: `list`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_OpenPlatform_ParamMissingMsg(list: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "qwY", originalKey: "Lark_OpenPlatform_ParamMissingMsg", lang: __lang)
            template = template.replacingOccurrences(of: "{{list}}", with: "\(`list`)")
            return template
        }
        @inlinable
        static var Mail_FileCantShareOrOpenViaThirdPartyApp_Toast: String {
            return LocalizedString(key: "IBk", originalKey: "Mail_FileCantShareOrOpenViaThirdPartyApp_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Mail_FileCantShareOrOpenViaThirdPartyApp_Toast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "IBk", originalKey: "Mail_FileCantShareOrOpenViaThirdPartyApp_Toast", lang: __lang)
        }
        @inlinable
        static var __OpenPlatform_AppActions_DisplayDomainDesc: String {
            return LocalizedString(key: "zz0", originalKey: "OpenPlatform_AppActions_DisplayDomainDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppActions_DisplayDomainDesc(_ root_domain: Any, lang __lang: Lang? = nil) -> String {
          return OpenPlatform_AppActions_DisplayDomainDesc(root_domain: `root_domain`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_AppActions_DisplayDomainDesc(root_domain: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "zz0", originalKey: "OpenPlatform_AppActions_DisplayDomainDesc", lang: __lang)
            template = template.replacingOccurrences(of: "{{root_domain}}", with: "\(`root_domain`)")
            return template
        }
        @inlinable
        static var OpenPlatform_AppActions_LoadingDesc: String {
            return LocalizedString(key: "04s", originalKey: "OpenPlatform_AppActions_LoadingDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppActions_LoadingDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "04s", originalKey: "OpenPlatform_AppActions_LoadingDesc", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppActions_NetworkErrToast: String {
            return LocalizedString(key: "XxQ", originalKey: "OpenPlatform_AppActions_NetworkErrToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppActions_NetworkErrToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "XxQ", originalKey: "OpenPlatform_AppActions_NetworkErrToast", lang: __lang)
        }
        @inlinable
        static var __OpenPlatform_AppErrPage_PageLoadFailedErrDesc: String {
            return LocalizedString(key: "WqM", originalKey: "OpenPlatform_AppErrPage_PageLoadFailedErrDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppErrPage_PageLoadFailedErrDesc(_ errorDesc: Any, _ errorCode: Any, lang __lang: Lang? = nil) -> String {
          return OpenPlatform_AppErrPage_PageLoadFailedErrDesc(errorDesc: `errorDesc`, errorCode: `errorCode`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_AppErrPage_PageLoadFailedErrDesc(errorDesc: Any, errorCode: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "WqM", originalKey: "OpenPlatform_AppErrPage_PageLoadFailedErrDesc", lang: __lang)
            template = template.replacingOccurrences(of: "{{errorDesc}}", with: "\(`errorDesc`)")
            template = template.replacingOccurrences(of: "{{errorCode}}", with: "\(`errorCode`)")
            return template
        }
        @inlinable
        static var OpenPlatform_AppRating_GoToRateLink: String {
            return LocalizedString(key: "Zg4", originalKey: "OpenPlatform_AppRating_GoToRateLink")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppRating_GoToRateLink(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Zg4", originalKey: "OpenPlatform_AppRating_GoToRateLink", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppRating_MyRatingTtl: String {
            return LocalizedString(key: "Fp8", originalKey: "OpenPlatform_AppRating_MyRatingTtl")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppRating_MyRatingTtl(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Fp8", originalKey: "OpenPlatform_AppRating_MyRatingTtl", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppRating_NotRatedYet: String {
            return LocalizedString(key: "6P8", originalKey: "OpenPlatform_AppRating_NotRatedYet")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppRating_NotRatedYet(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6P8", originalKey: "OpenPlatform_AppRating_NotRatedYet", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_GadgetErr_ClientVerTooLow: String {
            return LocalizedString(key: "PS4", originalKey: "OpenPlatform_GadgetErr_ClientVerTooLow")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_GadgetErr_ClientVerTooLow(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PS4", originalKey: "OpenPlatform_GadgetErr_ClientVerTooLow", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MobApp_AppPresents: String {
            return LocalizedString(key: "Loo", originalKey: "OpenPlatform_MobApp_AppPresents")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MobApp_AppPresents(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Loo", originalKey: "OpenPlatform_MobApp_AppPresents", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MoreAppFcns_DevDisabledFcns: String {
            return LocalizedString(key: "eUM", originalKey: "OpenPlatform_MoreAppFcns_DevDisabledFcns")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MoreAppFcns_DevDisabledFcns(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "eUM", originalKey: "OpenPlatform_MoreAppFcns_DevDisabledFcns", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MoreAppFcns_UnableToCopyLink: String {
            return LocalizedString(key: "w94", originalKey: "OpenPlatform_MoreAppFcns_UnableToCopyLink")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MoreAppFcns_UnableToCopyLink(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "w94", originalKey: "OpenPlatform_MoreAppFcns_UnableToCopyLink", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_MoreAppFcns_UnableToOpenInBr: String {
            return LocalizedString(key: "lio", originalKey: "OpenPlatform_MoreAppFcns_UnableToOpenInBr")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_MoreAppFcns_UnableToOpenInBr(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lio", originalKey: "OpenPlatform_MoreAppFcns_UnableToOpenInBr", lang: __lang)
        }
        @inlinable
        static var __OpenPlatform_Share_ParamWrongMsg: String {
            return LocalizedString(key: "BL0", originalKey: "OpenPlatform_Share_ParamWrongMsg")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_Share_ParamWrongMsg(_ list: Any, lang __lang: Lang? = nil) -> String {
          return OpenPlatform_Share_ParamWrongMsg(list: `list`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func OpenPlatform_Share_ParamWrongMsg(list: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "BL0", originalKey: "OpenPlatform_Share_ParamWrongMsg", lang: __lang)
            template = template.replacingOccurrences(of: "{{list}}", with: "\(`list`)")
            return template
        }
        @inlinable
        static var OpenPlatform_WebView_OnlineDebug_Cancel: String {
            return LocalizedString(key: "V6s", originalKey: "OpenPlatform_WebView_OnlineDebug_Cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_WebView_OnlineDebug_Cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "V6s", originalKey: "OpenPlatform_WebView_OnlineDebug_Cancel", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_WebView_OnlineDebug_Close_Info: String {
            return LocalizedString(key: "YAE", originalKey: "OpenPlatform_WebView_OnlineDebug_Close_Info")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_WebView_OnlineDebug_Close_Info(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YAE", originalKey: "OpenPlatform_WebView_OnlineDebug_Close_Info", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_WebView_OnlineDebug_Confirm: String {
            return LocalizedString(key: "Ex8", originalKey: "OpenPlatform_WebView_OnlineDebug_Confirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_WebView_OnlineDebug_Confirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ex8", originalKey: "OpenPlatform_WebView_OnlineDebug_Confirm", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_WebView_OnlineDebug_Open_Info: String {
            return LocalizedString(key: "lbg", originalKey: "OpenPlatform_WebView_OnlineDebug_Open_Info")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_WebView_OnlineDebug_Open_Info(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lbg", originalKey: "OpenPlatform_WebView_OnlineDebug_Open_Info", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_WebView_OnlineDebug_Panel: String {
            return LocalizedString(key: "TuA", originalKey: "OpenPlatform_WebView_OnlineDebug_Panel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_WebView_OnlineDebug_Panel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "TuA", originalKey: "OpenPlatform_WebView_OnlineDebug_Panel", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_WebView_OnlineDebug_Tip: String {
            return LocalizedString(key: "zNw", originalKey: "OpenPlatform_WebView_OnlineDebug_Tip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_WebView_OnlineDebug_Tip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zNw", originalKey: "OpenPlatform_WebView_OnlineDebug_Tip", lang: __lang)
        }
        @inlinable
        static var OpenPlatform__AppRating_UpdateRatingLink: String {
            return LocalizedString(key: "7wk", originalKey: "OpenPlatform__AppRating_UpdateRatingLink")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform__AppRating_UpdateRatingLink(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7wk", originalKey: "OpenPlatform__AppRating_UpdateRatingLink", lang: __lang)
        }
        @inlinable
        static var WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging: String {
            return LocalizedString(key: "mmQ", originalKey: "WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "mmQ", originalKey: "WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging", lang: __lang)
        }
        @inlinable
        static var WebAppTool_WebAppRemoteDebug_UnableToDebugCurrentPage: String {
            return LocalizedString(key: "XVc", originalKey: "WebAppTool_WebAppRemoteDebug_UnableToDebugCurrentPage")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func WebAppTool_WebAppRemoteDebug_UnableToDebugCurrentPage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "XVc", originalKey: "WebAppTool_WebAppRemoteDebug_UnableToDebugCurrentPage", lang: __lang)
        }
        @inlinable
        static var loading_failed: String {
            return LocalizedString(key: "vfM", originalKey: "loading_failed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func loading_failed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vfM", originalKey: "loading_failed", lang: __lang)
        }
        @inlinable
        static var url_illegal: String {
            return LocalizedString(key: "X0Y", originalKey: "url_illegal")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func url_illegal(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "X0Y", originalKey: "url_illegal", lang: __lang)
        }
    }
}
// swiftlint:enable all
