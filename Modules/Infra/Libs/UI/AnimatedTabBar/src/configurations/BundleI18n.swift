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
"Lark_Core_Exit_Navigation":{
"hash":"7Wo",
"#vars":0
},
"Lark_Core_More_AddApp_Button":{
"hash":"Iwg",
"#vars":0
},
"Lark_Core_More_EditApp_Button":{
"hash":"gjM",
"#vars":0
},
"Lark_Core_More_Navigation":{
"hash":"220",
"#vars":0
},
"Lark_Core_More_PinTab_Button":{
"hash":"Oak",
"#vars":0
},
"Lark_Core_More_RemoveTab_Button":{
"hash":"Wqk",
"#vars":0
},
"Lark_Core_More_ViewMoreTabs_Button":{
"hash":"ehY",
"#vars":0
},
"Lark_Core_NavbarAppAction_Remove_Button":{
"hash":"LVo",
"#vars":0
},
"Lark_Core_NavbarAppAction_Rename_Button":{
"hash":"bIo",
"#vars":0
},
"Lark_Core_NavbarAppAction_Reorder_Button":{
"hash":"s1w",
"#vars":0
},
"Lark_Legacy_BaseUiLoading":{
"hash":"ciI",
"#vars":0
},
"Lark_Legacy_BottomNavigation":{
"hash":"OyE",
"#vars":0
},
"Lark_Legacy_BottomNavigationItemMaxReachedToast":{
"hash":"Spo",
"#vars":1,
"normal_vars":["N"]
},
"Lark_Legacy_BottomNavigationItemMinimumToast":{
"hash":"4Pg",
"#vars":1,
"normal_vars":["N"]
},
"Lark_Legacy_Cancel":{
"hash":"ewo",
"#vars":0
},
"Lark_Legacy_Done":{
"hash":"vZw",
"#vars":0
},
"Lark_Legacy_Edit":{
"hash":"vy4",
"#vars":0
},
"Lark_Legacy_Navigation":{
"hash":"QgM",
"#vars":0
},
"Lark_Legacy_NavigationCantEmptyToast":{
"hash":"SG8",
"#vars":0
},
"Lark_Legacy_NavigationMore":{
"hash":"qmM",
"#vars":0
},
"Lark_Legacy_NavigationPreview":{
"hash":"34s",
"#vars":0
},
"Lark_Legacy_NetworkError":{
"hash":"Km8",
"#vars":0
},
"Lark_Legacy_PullEmptyResult":{
"hash":"bHo",
"#vars":0
},
"Lark_Legacy_SelectTip":{
"hash":"ow0",
"#vars":0
},
"Lark_Navbar_FrequentVisits_Mobile_Text":{
"hash":"0H8",
"#vars":0
},
"Lark_Navbar_More_Discovery_Button":{
"hash":"B4M",
"#vars":0
},
"Lark_Navbar_Open_Mobile_Button":{
"hash":"27o",
"#vars":0
},
"Lark_Navigation_EditBottomNavigationBar":{
"hash":"eYs",
"#vars":0
},
"Lark_Shortcuts_CloseCurrentTab_Text":{
"hash":"OMU",
"#vars":0
},
"Lark_SuperApp_More_PinToMore_Button":{
"hash":"RDI",
"#vars":0
},
"Lark_SuperApp_More_Recents_Title":{
"hash":"oWw",
"#vars":0
},
"Lark_iPad_UnableReorderFixedByAdmin":{
"hash":"/jQ",
"#vars":0
}
},
"name":"AnimatedTabBar",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.AnimatedTabBarAutoBundle, moduleName: "AnimatedTabBar", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.AnimatedTabBarAutoBundle, moduleName: "AnimatedTabBar", lang: lang) ?? key
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
    final class AnimatedTabBar {
        @inlinable
        static var Lark_Core_Exit_Navigation: String {
            return LocalizedString(key: "7Wo", originalKey: "Lark_Core_Exit_Navigation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_Exit_Navigation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "7Wo", originalKey: "Lark_Core_Exit_Navigation", lang: __lang)
        }
        @inlinable
        static var Lark_Core_More_AddApp_Button: String {
            return LocalizedString(key: "Iwg", originalKey: "Lark_Core_More_AddApp_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_More_AddApp_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Iwg", originalKey: "Lark_Core_More_AddApp_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_More_EditApp_Button: String {
            return LocalizedString(key: "gjM", originalKey: "Lark_Core_More_EditApp_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_More_EditApp_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "gjM", originalKey: "Lark_Core_More_EditApp_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_More_Navigation: String {
            return LocalizedString(key: "220", originalKey: "Lark_Core_More_Navigation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_More_Navigation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "220", originalKey: "Lark_Core_More_Navigation", lang: __lang)
        }
        @inlinable
        static var Lark_Core_More_PinTab_Button: String {
            return LocalizedString(key: "Oak", originalKey: "Lark_Core_More_PinTab_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_More_PinTab_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Oak", originalKey: "Lark_Core_More_PinTab_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_More_RemoveTab_Button: String {
            return LocalizedString(key: "Wqk", originalKey: "Lark_Core_More_RemoveTab_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_More_RemoveTab_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Wqk", originalKey: "Lark_Core_More_RemoveTab_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_More_ViewMoreTabs_Button: String {
            return LocalizedString(key: "ehY", originalKey: "Lark_Core_More_ViewMoreTabs_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_More_ViewMoreTabs_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ehY", originalKey: "Lark_Core_More_ViewMoreTabs_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_NavbarAppAction_Remove_Button: String {
            return LocalizedString(key: "LVo", originalKey: "Lark_Core_NavbarAppAction_Remove_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_NavbarAppAction_Remove_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "LVo", originalKey: "Lark_Core_NavbarAppAction_Remove_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_NavbarAppAction_Rename_Button: String {
            return LocalizedString(key: "bIo", originalKey: "Lark_Core_NavbarAppAction_Rename_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_NavbarAppAction_Rename_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bIo", originalKey: "Lark_Core_NavbarAppAction_Rename_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Core_NavbarAppAction_Reorder_Button: String {
            return LocalizedString(key: "s1w", originalKey: "Lark_Core_NavbarAppAction_Reorder_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_NavbarAppAction_Reorder_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "s1w", originalKey: "Lark_Core_NavbarAppAction_Reorder_Button", lang: __lang)
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
        static var Lark_Legacy_BottomNavigation: String {
            return LocalizedString(key: "OyE", originalKey: "Lark_Legacy_BottomNavigation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_BottomNavigation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "OyE", originalKey: "Lark_Legacy_BottomNavigation", lang: __lang)
        }
        @inlinable
        static var __Lark_Legacy_BottomNavigationItemMaxReachedToast: String {
            return LocalizedString(key: "Spo", originalKey: "Lark_Legacy_BottomNavigationItemMaxReachedToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_BottomNavigationItemMaxReachedToast(_ N: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_BottomNavigationItemMaxReachedToast(N: `N`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_BottomNavigationItemMaxReachedToast(N: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "Spo", originalKey: "Lark_Legacy_BottomNavigationItemMaxReachedToast", lang: __lang)
            template = template.replacingOccurrences(of: "{{N}}", with: "\(`N`)")
            return template
        }
        @inlinable
        static var __Lark_Legacy_BottomNavigationItemMinimumToast: String {
            return LocalizedString(key: "4Pg", originalKey: "Lark_Legacy_BottomNavigationItemMinimumToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_BottomNavigationItemMinimumToast(_ N: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Legacy_BottomNavigationItemMinimumToast(N: `N`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Legacy_BottomNavigationItemMinimumToast(N: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "4Pg", originalKey: "Lark_Legacy_BottomNavigationItemMinimumToast", lang: __lang)
            template = template.replacingOccurrences(of: "{{N}}", with: "\(`N`)")
            return template
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
        static var Lark_Legacy_Done: String {
            return LocalizedString(key: "vZw", originalKey: "Lark_Legacy_Done")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Done(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vZw", originalKey: "Lark_Legacy_Done", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Edit: String {
            return LocalizedString(key: "vy4", originalKey: "Lark_Legacy_Edit")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Edit(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vy4", originalKey: "Lark_Legacy_Edit", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Navigation: String {
            return LocalizedString(key: "QgM", originalKey: "Lark_Legacy_Navigation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Navigation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "QgM", originalKey: "Lark_Legacy_Navigation", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NavigationCantEmptyToast: String {
            return LocalizedString(key: "SG8", originalKey: "Lark_Legacy_NavigationCantEmptyToast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NavigationCantEmptyToast(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "SG8", originalKey: "Lark_Legacy_NavigationCantEmptyToast", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NavigationMore: String {
            return LocalizedString(key: "qmM", originalKey: "Lark_Legacy_NavigationMore")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NavigationMore(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qmM", originalKey: "Lark_Legacy_NavigationMore", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NavigationPreview: String {
            return LocalizedString(key: "34s", originalKey: "Lark_Legacy_NavigationPreview")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NavigationPreview(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "34s", originalKey: "Lark_Legacy_NavigationPreview", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_NetworkError: String {
            return LocalizedString(key: "Km8", originalKey: "Lark_Legacy_NetworkError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_NetworkError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Km8", originalKey: "Lark_Legacy_NetworkError", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_PullEmptyResult: String {
            return LocalizedString(key: "bHo", originalKey: "Lark_Legacy_PullEmptyResult")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_PullEmptyResult(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bHo", originalKey: "Lark_Legacy_PullEmptyResult", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_SelectTip: String {
            return LocalizedString(key: "ow0", originalKey: "Lark_Legacy_SelectTip")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_SelectTip(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ow0", originalKey: "Lark_Legacy_SelectTip", lang: __lang)
        }
        @inlinable
        static var Lark_Navbar_FrequentVisits_Mobile_Text: String {
            return LocalizedString(key: "0H8", originalKey: "Lark_Navbar_FrequentVisits_Mobile_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Navbar_FrequentVisits_Mobile_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "0H8", originalKey: "Lark_Navbar_FrequentVisits_Mobile_Text", lang: __lang)
        }
        @inlinable
        static var Lark_Navbar_More_Discovery_Button: String {
            return LocalizedString(key: "B4M", originalKey: "Lark_Navbar_More_Discovery_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Navbar_More_Discovery_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "B4M", originalKey: "Lark_Navbar_More_Discovery_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Navbar_Open_Mobile_Button: String {
            return LocalizedString(key: "27o", originalKey: "Lark_Navbar_Open_Mobile_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Navbar_Open_Mobile_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "27o", originalKey: "Lark_Navbar_Open_Mobile_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Navigation_EditBottomNavigationBar: String {
            return LocalizedString(key: "eYs", originalKey: "Lark_Navigation_EditBottomNavigationBar")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Navigation_EditBottomNavigationBar(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "eYs", originalKey: "Lark_Navigation_EditBottomNavigationBar", lang: __lang)
        }
        @inlinable
        static var Lark_Shortcuts_CloseCurrentTab_Text: String {
            return LocalizedString(key: "OMU", originalKey: "Lark_Shortcuts_CloseCurrentTab_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Shortcuts_CloseCurrentTab_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "OMU", originalKey: "Lark_Shortcuts_CloseCurrentTab_Text", lang: __lang)
        }
        @inlinable
        static var Lark_SuperApp_More_PinToMore_Button: String {
            return LocalizedString(key: "RDI", originalKey: "Lark_SuperApp_More_PinToMore_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_SuperApp_More_PinToMore_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "RDI", originalKey: "Lark_SuperApp_More_PinToMore_Button", lang: __lang)
        }
        @inlinable
        static var Lark_SuperApp_More_Recents_Title: String {
            return LocalizedString(key: "oWw", originalKey: "Lark_SuperApp_More_Recents_Title")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_SuperApp_More_Recents_Title(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "oWw", originalKey: "Lark_SuperApp_More_Recents_Title", lang: __lang)
        }
        @inlinable
        static var Lark_iPad_UnableReorderFixedByAdmin: String {
            return LocalizedString(key: "/jQ", originalKey: "Lark_iPad_UnableReorderFixedByAdmin")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_iPad_UnableReorderFixedByAdmin(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "/jQ", originalKey: "Lark_iPad_UnableReorderFixedByAdmin", lang: __lang)
        }
    }
}
// swiftlint:enable all
