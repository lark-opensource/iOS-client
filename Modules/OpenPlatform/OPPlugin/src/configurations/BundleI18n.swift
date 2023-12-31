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
"Lark_Legacy_Confirm":{
"hash":"q/I",
"#vars":0
},
"LittleApp_OpenLocation_SearchPlacePlaceholder":{
"hash":"sXY",
"#vars":0
},
"OpenPlatform_AppCenter_IKnow":{
"hash":"JGQ",
"#vars":0
},
"OpenPlatform_Workplace_SafetyWarning_OpenFailed":{
"hash":"qaY",
"#vars":0
},
"OpenPlatform_Workplace_SafetyWarning_SaveFailed":{
"hash":"ilw",
"#vars":0
},
"OpenPlatform_gadgetRequestApply":{
"hash":"YcM",
"#vars":0
},
"OpenPlatform_gadgetRequestApplyToast":{
"hash":"/AM",
"#vars":0
},
"OpenPlatform_gadgetRequestCancel":{
"hash":"duI",
"#vars":0
},
"OpenPlatform_gadgetRequestContent":{
"hash":"lPM",
"#vars":0
},
"OpenPlatform_gadgetRequestTitle":{
"hash":"9ok",
"#vars":0
},
"OpenPlatform_gadgetRequest_SendFailedToast":{
"hash":"GMw",
"#vars":0
},
"OpenPlatform_gadgetRequest_SendingToast":{
"hash":"Mvk",
"#vars":0
},
"OpenPlatform_gadgetRequest_allPermittedTitle":{
"hash":"ba0",
"#vars":0
},
"OpenPlatform_gadgetRequest_exceedLimitTitle":{
"hash":"sqA",
"#vars":0
},
"OpenPlatform_gadgetRequest_notInstall":{
"hash":"bHo",
"#vars":0
},
"OpenPlatform_gadgetRequest_remindContent":{
"hash":"lAQ",
"#vars":0
},
"OpenPlatform_gadgetRequest_repeatApplication":{
"hash":"EFg",
"#vars":0
},
"accelerometer_is_running":{
"hash":"4Yc",
"#vars":0
},
"auth_content_must_non_null":{
"hash":"Gq0",
"#vars":0
},
"cancel":{
"hash":"0HM",
"#vars":0
},
"continue_show_modal_exit":{
"hash":"Y1U",
"#vars":0
},
"continue_show_modal_no":{
"hash":"zuI",
"#vars":0
},
"continue_show_modal_tip":{
"hash":"ym0",
"#vars":0
},
"determine":{
"hash":"13k",
"#vars":0
},
"done":{
"hash":"ZsM",
"#vars":0
},
"itemlist_non_null":{
"hash":"q+M",
"#vars":0
},
"microapp_m_keyboard_done":{
"hash":"IPI",
"#vars":0
},
"not_set_lock_screen_password":{
"hash":"dAw",
"#vars":0
},
"not_support_accelerometers":{
"hash":"I/E",
"#vars":0
},
"scan_code_running":{
"hash":"Kmw",
"#vars":0
},
"show_prompt_ok":{
"hash":"uYk",
"#vars":0
},
"show_prompt_placeholder":{
"hash":"NOg",
"#vars":0
},
"telephone_service_failed":{
"hash":"9sc",
"#vars":0
},
"title_null":{
"hash":"mpY",
"#vars":0
},
"title_or_content_non_null":{
"hash":"Fkw",
"#vars":0
},
"unlock_falied":{
"hash":"KC8",
"#vars":0
},
"user_canceled":{
"hash":"hgk",
"#vars":0
}
},
"name":"OPPlugin",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.OPPluginAutoBundle, moduleName: "OPPlugin", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.OPPluginAutoBundle, moduleName: "OPPlugin", lang: lang) ?? key
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
    final class OPPlugin {
        @inlinable
        static var Lark_Legacy_Confirm: String {
            return LocalizedString(key: "q/I", originalKey: "Lark_Legacy_Confirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Confirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "q/I", originalKey: "Lark_Legacy_Confirm", lang: __lang)
        }
        @inlinable
        static var LittleApp_OpenLocation_SearchPlacePlaceholder: String {
            return LocalizedString(key: "sXY", originalKey: "LittleApp_OpenLocation_SearchPlacePlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func LittleApp_OpenLocation_SearchPlacePlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "sXY", originalKey: "LittleApp_OpenLocation_SearchPlacePlaceholder", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_AppCenter_IKnow: String {
            return LocalizedString(key: "JGQ", originalKey: "OpenPlatform_AppCenter_IKnow")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_AppCenter_IKnow(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "JGQ", originalKey: "OpenPlatform_AppCenter_IKnow", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_Workplace_SafetyWarning_OpenFailed: String {
            return LocalizedString(key: "qaY", originalKey: "OpenPlatform_Workplace_SafetyWarning_OpenFailed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_Workplace_SafetyWarning_OpenFailed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qaY", originalKey: "OpenPlatform_Workplace_SafetyWarning_OpenFailed", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_Workplace_SafetyWarning_SaveFailed: String {
            return LocalizedString(key: "ilw", originalKey: "OpenPlatform_Workplace_SafetyWarning_SaveFailed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_Workplace_SafetyWarning_SaveFailed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ilw", originalKey: "OpenPlatform_Workplace_SafetyWarning_SaveFailed", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequestApply: String {
            return LocalizedString(key: "YcM", originalKey: "OpenPlatform_gadgetRequestApply")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequestApply(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "YcM", originalKey: "OpenPlatform_gadgetRequestApply", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequestApplyToast: String {
            return LocalizedString(key: "/AM", originalKey: "OpenPlatform_gadgetRequestApplyToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequestApplyToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/AM", originalKey: "OpenPlatform_gadgetRequestApplyToast", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequestCancel: String {
            return LocalizedString(key: "duI", originalKey: "OpenPlatform_gadgetRequestCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequestCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "duI", originalKey: "OpenPlatform_gadgetRequestCancel", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequestContent: String {
            return LocalizedString(key: "lPM", originalKey: "OpenPlatform_gadgetRequestContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequestContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lPM", originalKey: "OpenPlatform_gadgetRequestContent", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequestTitle: String {
            return LocalizedString(key: "9ok", originalKey: "OpenPlatform_gadgetRequestTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequestTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9ok", originalKey: "OpenPlatform_gadgetRequestTitle", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_SendFailedToast: String {
            return LocalizedString(key: "GMw", originalKey: "OpenPlatform_gadgetRequest_SendFailedToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_SendFailedToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "GMw", originalKey: "OpenPlatform_gadgetRequest_SendFailedToast", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_SendingToast: String {
            return LocalizedString(key: "Mvk", originalKey: "OpenPlatform_gadgetRequest_SendingToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_SendingToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Mvk", originalKey: "OpenPlatform_gadgetRequest_SendingToast", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_allPermittedTitle: String {
            return LocalizedString(key: "ba0", originalKey: "OpenPlatform_gadgetRequest_allPermittedTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_allPermittedTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ba0", originalKey: "OpenPlatform_gadgetRequest_allPermittedTitle", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_exceedLimitTitle: String {
            return LocalizedString(key: "sqA", originalKey: "OpenPlatform_gadgetRequest_exceedLimitTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_exceedLimitTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "sqA", originalKey: "OpenPlatform_gadgetRequest_exceedLimitTitle", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_notInstall: String {
            return LocalizedString(key: "bHo", originalKey: "OpenPlatform_gadgetRequest_notInstall")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_notInstall(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bHo", originalKey: "OpenPlatform_gadgetRequest_notInstall", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_remindContent: String {
            return LocalizedString(key: "lAQ", originalKey: "OpenPlatform_gadgetRequest_remindContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_remindContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lAQ", originalKey: "OpenPlatform_gadgetRequest_remindContent", lang: __lang)
        }
        @inlinable
        static var OpenPlatform_gadgetRequest_repeatApplication: String {
            return LocalizedString(key: "EFg", originalKey: "OpenPlatform_gadgetRequest_repeatApplication")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func OpenPlatform_gadgetRequest_repeatApplication(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "EFg", originalKey: "OpenPlatform_gadgetRequest_repeatApplication", lang: __lang)
        }
        @inlinable
        static var accelerometer_is_running: String {
            return LocalizedString(key: "4Yc", originalKey: "accelerometer_is_running")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func accelerometer_is_running(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4Yc", originalKey: "accelerometer_is_running", lang: __lang)
        }
        @inlinable
        static var auth_content_must_non_null: String {
            return LocalizedString(key: "Gq0", originalKey: "auth_content_must_non_null")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func auth_content_must_non_null(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Gq0", originalKey: "auth_content_must_non_null", lang: __lang)
        }
        @inlinable
        static var cancel: String {
            return LocalizedString(key: "0HM", originalKey: "cancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func cancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "0HM", originalKey: "cancel", lang: __lang)
        }
        @inlinable
        static var continue_show_modal_exit: String {
            return LocalizedString(key: "Y1U", originalKey: "continue_show_modal_exit")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func continue_show_modal_exit(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Y1U", originalKey: "continue_show_modal_exit", lang: __lang)
        }
        @inlinable
        static var continue_show_modal_no: String {
            return LocalizedString(key: "zuI", originalKey: "continue_show_modal_no")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func continue_show_modal_no(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zuI", originalKey: "continue_show_modal_no", lang: __lang)
        }
        @inlinable
        static var continue_show_modal_tip: String {
            return LocalizedString(key: "ym0", originalKey: "continue_show_modal_tip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func continue_show_modal_tip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ym0", originalKey: "continue_show_modal_tip", lang: __lang)
        }
        @inlinable
        static var determine: String {
            return LocalizedString(key: "13k", originalKey: "determine")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func determine(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "13k", originalKey: "determine", lang: __lang)
        }
        @inlinable
        static var done: String {
            return LocalizedString(key: "ZsM", originalKey: "done")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func done(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZsM", originalKey: "done", lang: __lang)
        }
        @inlinable
        static var itemlist_non_null: String {
            return LocalizedString(key: "q+M", originalKey: "itemlist_non_null")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func itemlist_non_null(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "q+M", originalKey: "itemlist_non_null", lang: __lang)
        }
        @inlinable
        static var microapp_m_keyboard_done: String {
            return LocalizedString(key: "IPI", originalKey: "microapp_m_keyboard_done")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func microapp_m_keyboard_done(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "IPI", originalKey: "microapp_m_keyboard_done", lang: __lang)
        }
        @inlinable
        static var not_set_lock_screen_password: String {
            return LocalizedString(key: "dAw", originalKey: "not_set_lock_screen_password")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func not_set_lock_screen_password(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "dAw", originalKey: "not_set_lock_screen_password", lang: __lang)
        }
        @inlinable
        static var not_support_accelerometers: String {
            return LocalizedString(key: "I/E", originalKey: "not_support_accelerometers")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func not_support_accelerometers(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "I/E", originalKey: "not_support_accelerometers", lang: __lang)
        }
        @inlinable
        static var scan_code_running: String {
            return LocalizedString(key: "Kmw", originalKey: "scan_code_running")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func scan_code_running(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Kmw", originalKey: "scan_code_running", lang: __lang)
        }
        @inlinable
        static var show_prompt_ok: String {
            return LocalizedString(key: "uYk", originalKey: "show_prompt_ok")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func show_prompt_ok(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "uYk", originalKey: "show_prompt_ok", lang: __lang)
        }
        @inlinable
        static var show_prompt_placeholder: String {
            return LocalizedString(key: "NOg", originalKey: "show_prompt_placeholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func show_prompt_placeholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "NOg", originalKey: "show_prompt_placeholder", lang: __lang)
        }
        @inlinable
        static var telephone_service_failed: String {
            return LocalizedString(key: "9sc", originalKey: "telephone_service_failed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func telephone_service_failed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9sc", originalKey: "telephone_service_failed", lang: __lang)
        }
        @inlinable
        static var title_null: String {
            return LocalizedString(key: "mpY", originalKey: "title_null")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func title_null(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "mpY", originalKey: "title_null", lang: __lang)
        }
        @inlinable
        static var title_or_content_non_null: String {
            return LocalizedString(key: "Fkw", originalKey: "title_or_content_non_null")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func title_or_content_non_null(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Fkw", originalKey: "title_or_content_non_null", lang: __lang)
        }
        @inlinable
        static var unlock_falied: String {
            return LocalizedString(key: "KC8", originalKey: "unlock_falied")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func unlock_falied(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "KC8", originalKey: "unlock_falied", lang: __lang)
        }
        @inlinable
        static var user_canceled: String {
            return LocalizedString(key: "hgk", originalKey: "user_canceled")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func user_canceled(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "hgk", originalKey: "user_canceled", lang: __lang)
        }
    }
}
// swiftlint:enable all
