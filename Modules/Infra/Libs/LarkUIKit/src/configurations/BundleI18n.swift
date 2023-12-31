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
"Lark_Core_CameraAccessForPhoto_Desc":{
"hash":"Eg4",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_Core_CameraAccess_Title":{
"hash":"L4Q",
"#vars":0
},
"Lark_Groups_PostPhotostrip":{
"hash":"bvQ",
"#vars":0
},
"Lark_Groups_Pulldowntorefresh":{
"hash":"tf8",
"#vars":0
},
"Lark_Groups_RefreshLoading":{
"hash":"HeQ",
"#vars":0
},
"Lark_Groups_Releasetorefresh":{
"hash":"vxI",
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
"Lark_Legacy_Completed":{
"hash":"4Qc",
"#vars":0
},
"Lark_Legacy_ConfirmTip":{
"hash":"p7A",
"#vars":0
},
"Lark_Legacy_HasSelected":{
"hash":"aAs",
"#vars":0
},
"Lark_Legacy_LanguageSystem":{
"hash":"AFs",
"#vars":1,
"normal_vars":["language"]
},
"Lark_Legacy_LoadFailedRetryTip":{
"hash":"FNM",
"#vars":0
},
"Lark_Legacy_Search":{
"hash":"Wag",
"#vars":0
},
"Lark_Legacy_SearchViewPlaceholder":{
"hash":"U0g",
"#vars":0
},
"Lark_Legacy_SelectedNumberOfChats":{
"hash":"oag",
"#vars":1,
"normal_vars":["chat_count"]
},
"Lark_Legacy_SelectedNumberOfPeople":{
"hash":"7gQ",
"#vars":0
},
"Lark_Legacy_SelectedSingleChat":{
"hash":"DM4",
"#vars":1,
"normal_vars":["chat_count"]
},
"Lark_Legacy_SelectedSinglePerson":{
"hash":"XmI",
"#vars":0
},
"Lark_Legacy_Setting":{
"hash":"vTc",
"#vars":0
},
"Lark_Legacy_Sure":{
"hash":"DrA",
"#vars":0
},
"Lark_Login_LanguageSettingTitle":{
"hash":"8+Q",
"#vars":0
},
"Lark_Login_PlaceholderOfSearchInput":{
"hash":"Wig",
"#vars":0
},
"Lark_Login_TitleOfCountryCode":{
"hash":"Jqs",
"#vars":0
},
"Lark_Onboard_WelcomeToFeishu":{
"hash":"G7U",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"LittleApp_WebAppMenu_PageLoadingDesc":{
"hash":"Xg8",
"#vars":0
},
"OpenPlatform_MoreAppFcns_DevDisabledFcns":{
"hash":"eUM",
"#vars":0
}
},
"name":"LarkUIKit",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkUIKitAutoBundle, moduleName: "LarkUIKit", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkUIKitAutoBundle, moduleName: "LarkUIKit", lang: lang) ?? key
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
    final class LarkUIKit {
        @inlinable
        static var __Lark_Core_CameraAccessForPhoto_Desc: String {
            return LocalizedString(key: "Eg4", originalKey: "Lark_Core_CameraAccessForPhoto_Desc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Core_CameraAccessForPhoto_Desc(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "Eg4", originalKey: "Lark_Core_CameraAccessForPhoto_Desc", lang: __lang)
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
        static var Lark_Groups_PostPhotostrip: String {
            return LocalizedString(key: "bvQ", originalKey: "Lark_Groups_PostPhotostrip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_PostPhotostrip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bvQ", originalKey: "Lark_Groups_PostPhotostrip", lang: __lang)
        }
        @inlinable
        static var Lark_Groups_Pulldowntorefresh: String {
            return LocalizedString(key: "tf8", originalKey: "Lark_Groups_Pulldowntorefresh")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_Pulldowntorefresh(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "tf8", originalKey: "Lark_Groups_Pulldowntorefresh", lang: __lang)
        }
        @inlinable
        static var Lark_Groups_RefreshLoading: String {
            return LocalizedString(key: "HeQ", originalKey: "Lark_Groups_RefreshLoading")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_RefreshLoading(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HeQ", originalKey: "Lark_Groups_RefreshLoading", lang: __lang)
        }
        @inlinable
        static var Lark_Groups_Releasetorefresh: String {
            return LocalizedString(key: "vxI", originalKey: "Lark_Groups_Releasetorefresh")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Groups_Releasetorefresh(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vxI", originalKey: "Lark_Groups_Releasetorefresh", lang: __lang)
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
        static var Lark_Legacy_Completed: String {
            return LocalizedString(key: "4Qc", originalKey: "Lark_Legacy_Completed")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Completed(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4Qc", originalKey: "Lark_Legacy_Completed", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ConfirmTip: String {
            return LocalizedString(key: "p7A", originalKey: "Lark_Legacy_ConfirmTip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ConfirmTip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "p7A", originalKey: "Lark_Legacy_ConfirmTip", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_HasSelected: String {
            return LocalizedString(key: "aAs", originalKey: "Lark_Legacy_HasSelected")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_HasSelected(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "aAs", originalKey: "Lark_Legacy_HasSelected", lang: __lang)
        }
        @inlinable
        static var __Lark_Legacy_LanguageSystem: String {
            return LocalizedString(key: "AFs", originalKey: "Lark_Legacy_LanguageSystem")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LanguageSystem(_ language: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_LanguageSystem(language: `language`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_LanguageSystem(language: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "AFs", originalKey: "Lark_Legacy_LanguageSystem", lang: __lang)
            template = template.replacingOccurrences(of: "{{language}}", with: "\(`language`)")
            return template
        }
        @inlinable
        static var Lark_Legacy_LoadFailedRetryTip: String {
            return LocalizedString(key: "FNM", originalKey: "Lark_Legacy_LoadFailedRetryTip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LoadFailedRetryTip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "FNM", originalKey: "Lark_Legacy_LoadFailedRetryTip", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Search: String {
            return LocalizedString(key: "Wag", originalKey: "Lark_Legacy_Search")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Search(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Wag", originalKey: "Lark_Legacy_Search", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SearchViewPlaceholder: String {
            return LocalizedString(key: "U0g", originalKey: "Lark_Legacy_SearchViewPlaceholder")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SearchViewPlaceholder(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "U0g", originalKey: "Lark_Legacy_SearchViewPlaceholder", lang: __lang)
        }
        @inlinable
        static var __Lark_Legacy_SelectedNumberOfChats: String {
            return LocalizedString(key: "oag", originalKey: "Lark_Legacy_SelectedNumberOfChats")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SelectedNumberOfChats(_ chat_count: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_SelectedNumberOfChats(chat_count: `chat_count`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_SelectedNumberOfChats(chat_count: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "oag", originalKey: "Lark_Legacy_SelectedNumberOfChats", lang: __lang)
            template = template.replacingOccurrences(of: "{{chat_count}}", with: "\(`chat_count`)")
            return template
        }
        @inlinable
        static var Lark_Legacy_SelectedNumberOfPeople: String {
            return LocalizedString(key: "7gQ", originalKey: "Lark_Legacy_SelectedNumberOfPeople")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SelectedNumberOfPeople(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7gQ", originalKey: "Lark_Legacy_SelectedNumberOfPeople", lang: __lang)
        }
        @inlinable
        static var __Lark_Legacy_SelectedSingleChat: String {
            return LocalizedString(key: "DM4", originalKey: "Lark_Legacy_SelectedSingleChat")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SelectedSingleChat(_ chat_count: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_SelectedSingleChat(chat_count: `chat_count`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_SelectedSingleChat(chat_count: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "DM4", originalKey: "Lark_Legacy_SelectedSingleChat", lang: __lang)
            template = template.replacingOccurrences(of: "{{chat_count}}", with: "\(`chat_count`)")
            return template
        }
        @inlinable
        static var Lark_Legacy_SelectedSinglePerson: String {
            return LocalizedString(key: "XmI", originalKey: "Lark_Legacy_SelectedSinglePerson")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SelectedSinglePerson(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "XmI", originalKey: "Lark_Legacy_SelectedSinglePerson", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Setting: String {
            return LocalizedString(key: "vTc", originalKey: "Lark_Legacy_Setting")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Setting(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vTc", originalKey: "Lark_Legacy_Setting", lang: __lang)
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
        static var Lark_Login_LanguageSettingTitle: String {
            return LocalizedString(key: "8+Q", originalKey: "Lark_Login_LanguageSettingTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_LanguageSettingTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "8+Q", originalKey: "Lark_Login_LanguageSettingTitle", lang: __lang)
        }
        @inlinable
        static var Lark_Login_PlaceholderOfSearchInput: String {
            return LocalizedString(key: "Wig", originalKey: "Lark_Login_PlaceholderOfSearchInput")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_PlaceholderOfSearchInput(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Wig", originalKey: "Lark_Login_PlaceholderOfSearchInput", lang: __lang)
        }
        @inlinable
        static var Lark_Login_TitleOfCountryCode: String {
            return LocalizedString(key: "Jqs", originalKey: "Lark_Login_TitleOfCountryCode")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Login_TitleOfCountryCode(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Jqs", originalKey: "Lark_Login_TitleOfCountryCode", lang: __lang)
        }
        @inlinable
        static var __Lark_Onboard_WelcomeToFeishu: String {
            return LocalizedString(key: "G7U", originalKey: "Lark_Onboard_WelcomeToFeishu")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Onboard_WelcomeToFeishu(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "G7U", originalKey: "Lark_Onboard_WelcomeToFeishu", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var LittleApp_WebAppMenu_PageLoadingDesc: String {
            return LocalizedString(key: "Xg8", originalKey: "LittleApp_WebAppMenu_PageLoadingDesc")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func LittleApp_WebAppMenu_PageLoadingDesc(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Xg8", originalKey: "LittleApp_WebAppMenu_PageLoadingDesc", lang: __lang)
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
    }
}
// swiftlint:enable all
