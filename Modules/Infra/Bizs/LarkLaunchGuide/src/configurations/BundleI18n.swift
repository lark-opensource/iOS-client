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
"Lark_UserGrowth_GuideFifthPageContent":{
"hash":"oek",
"#vars":1,
"normal_vars":["APP_DISPLAY_NAME"]
},
"Lark_UserGrowth_GuideFifthPageTitle":{
"hash":"Oq8",
"#vars":0
},
"Lark_UserGrowth_GuideFirstPageContent":{
"hash":"HSc",
"#vars":0
},
"Lark_UserGrowth_GuideFirstPageTitle":{
"hash":"1EQ",
"#vars":0
},
"Lark_UserGrowth_GuideForthPageContent":{
"hash":"t3s",
"#vars":0
},
"Lark_UserGrowth_GuideForthPageTitle":{
"hash":"zJY",
"#vars":0
},
"Lark_UserGrowth_GuideSecondPageContent":{
"hash":"l1c",
"#vars":0
},
"Lark_UserGrowth_GuideSecondPageTitle":{
"hash":"cwc",
"#vars":0
},
"Lark_UserGrowth_GuideThirdPageContent":{
"hash":"1bI",
"#vars":0
},
"Lark_UserGrowth_GuideThirdPageTitle":{
"hash":"CnU",
"#vars":0
}
},
"name":"LarkLaunchGuide",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkLaunchGuideAutoBundle, moduleName: "LarkLaunchGuide", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkLaunchGuideAutoBundle, moduleName: "LarkLaunchGuide", lang: lang) ?? key
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
    final class LarkLaunchGuide {
        @inlinable
        static var __Lark_UserGrowth_GuideFifthPageContent: String {
            return LocalizedString(key: "oek", originalKey: "Lark_UserGrowth_GuideFifthPageContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_UserGrowth_GuideFifthPageContent(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "oek", originalKey: "Lark_UserGrowth_GuideFifthPageContent", lang: __lang)
            template = template.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
            return template
        }
        @inlinable
        static var Lark_UserGrowth_GuideFifthPageTitle: String {
            return LocalizedString(key: "Oq8", originalKey: "Lark_UserGrowth_GuideFifthPageTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideFifthPageTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Oq8", originalKey: "Lark_UserGrowth_GuideFifthPageTitle", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideFirstPageContent: String {
            return LocalizedString(key: "HSc", originalKey: "Lark_UserGrowth_GuideFirstPageContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideFirstPageContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HSc", originalKey: "Lark_UserGrowth_GuideFirstPageContent", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideFirstPageTitle: String {
            return LocalizedString(key: "1EQ", originalKey: "Lark_UserGrowth_GuideFirstPageTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideFirstPageTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "1EQ", originalKey: "Lark_UserGrowth_GuideFirstPageTitle", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideForthPageContent: String {
            return LocalizedString(key: "t3s", originalKey: "Lark_UserGrowth_GuideForthPageContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideForthPageContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "t3s", originalKey: "Lark_UserGrowth_GuideForthPageContent", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideForthPageTitle: String {
            return LocalizedString(key: "zJY", originalKey: "Lark_UserGrowth_GuideForthPageTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideForthPageTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "zJY", originalKey: "Lark_UserGrowth_GuideForthPageTitle", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideSecondPageContent: String {
            return LocalizedString(key: "l1c", originalKey: "Lark_UserGrowth_GuideSecondPageContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideSecondPageContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "l1c", originalKey: "Lark_UserGrowth_GuideSecondPageContent", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideSecondPageTitle: String {
            return LocalizedString(key: "cwc", originalKey: "Lark_UserGrowth_GuideSecondPageTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideSecondPageTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "cwc", originalKey: "Lark_UserGrowth_GuideSecondPageTitle", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideThirdPageContent: String {
            return LocalizedString(key: "1bI", originalKey: "Lark_UserGrowth_GuideThirdPageContent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideThirdPageContent(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "1bI", originalKey: "Lark_UserGrowth_GuideThirdPageContent", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_GuideThirdPageTitle: String {
            return LocalizedString(key: "CnU", originalKey: "Lark_UserGrowth_GuideThirdPageTitle")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_GuideThirdPageTitle(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "CnU", originalKey: "Lark_UserGrowth_GuideThirdPageTitle", lang: __lang)
        }
    }
}
// swiftlint:enable all
