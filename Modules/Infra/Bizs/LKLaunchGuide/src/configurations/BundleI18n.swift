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
"Lark_Global_Registration_StarterPage_GetStarted_Button":{
"hash":"bKc",
"#vars":0
},
"Lark_Marketing_Feishu_MainSlogan_2023":{
"hash":"l1s",
"#vars":0
},
"Lark_Marketing_Feishu_SubSlogan_2023":{
"hash":"CbQ",
"#vars":0
},
"Lark_Marketing_Lark_MainSlogan_2023":{
"hash":"jS8",
"#vars":0
},
"Lark_Marketing_Lark_SubSlogan_2023":{
"hash":"PZM",
"#vars":0
},
"Lark_Passport_Newsignup_LoginButton":{
"hash":"SNY",
"#vars":0
},
"Lark_Passport_Newsignup_SignUpTeamButton":{
"hash":"scU",
"#vars":1,
"normal_vars":["BrandName"]
},
"Lark_UserGrowth_ButtonVCTouristEndPage":{
"hash":"9lY",
"#vars":0
},
"Lark_UserGrowth_DescVCTouristEndPage":{
"hash":"40E",
"#vars":0
},
"Lark_UserGrowth_TitleVCTouristEndPage":{
"hash":"qII",
"#vars":0
}
},
"name":"LKLaunchGuide",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LKLaunchGuideAutoBundle, moduleName: "LKLaunchGuide", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LKLaunchGuideAutoBundle, moduleName: "LKLaunchGuide", lang: lang) ?? key
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
    final class LKLaunchGuide {
        @inlinable
        static var Lark_Global_Registration_StarterPage_GetStarted_Button: String {
            return LocalizedString(key: "bKc", originalKey: "Lark_Global_Registration_StarterPage_GetStarted_Button")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Global_Registration_StarterPage_GetStarted_Button(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "bKc", originalKey: "Lark_Global_Registration_StarterPage_GetStarted_Button", lang: __lang)
        }
        @inlinable
        static var Lark_Marketing_Feishu_MainSlogan_2023: String {
            return LocalizedString(key: "l1s", originalKey: "Lark_Marketing_Feishu_MainSlogan_2023")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Marketing_Feishu_MainSlogan_2023(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "l1s", originalKey: "Lark_Marketing_Feishu_MainSlogan_2023", lang: __lang)
        }
        @inlinable
        static var Lark_Marketing_Feishu_SubSlogan_2023: String {
            return LocalizedString(key: "CbQ", originalKey: "Lark_Marketing_Feishu_SubSlogan_2023")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Marketing_Feishu_SubSlogan_2023(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "CbQ", originalKey: "Lark_Marketing_Feishu_SubSlogan_2023", lang: __lang)
        }
        @inlinable
        static var Lark_Marketing_Lark_MainSlogan_2023: String {
            return LocalizedString(key: "jS8", originalKey: "Lark_Marketing_Lark_MainSlogan_2023")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Marketing_Lark_MainSlogan_2023(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "jS8", originalKey: "Lark_Marketing_Lark_MainSlogan_2023", lang: __lang)
        }
        @inlinable
        static var Lark_Marketing_Lark_SubSlogan_2023: String {
            return LocalizedString(key: "PZM", originalKey: "Lark_Marketing_Lark_SubSlogan_2023")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Marketing_Lark_SubSlogan_2023(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "PZM", originalKey: "Lark_Marketing_Lark_SubSlogan_2023", lang: __lang)
        }
        @inlinable
        static var Lark_Passport_Newsignup_LoginButton: String {
            return LocalizedString(key: "SNY", originalKey: "Lark_Passport_Newsignup_LoginButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Passport_Newsignup_LoginButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "SNY", originalKey: "Lark_Passport_Newsignup_LoginButton", lang: __lang)
        }
        @inlinable
        static var __Lark_Passport_Newsignup_SignUpTeamButton: String {
            return LocalizedString(key: "scU", originalKey: "Lark_Passport_Newsignup_SignUpTeamButton")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Passport_Newsignup_SignUpTeamButton(_ BrandName: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Passport_Newsignup_SignUpTeamButton(BrandName: `BrandName`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Passport_Newsignup_SignUpTeamButton(BrandName: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "scU", originalKey: "Lark_Passport_Newsignup_SignUpTeamButton", lang: __lang)
            template = template.replacingOccurrences(of: "{{BrandName}}", with: "\(`BrandName`)")
            return template
        }
        @inlinable
        static var Lark_UserGrowth_ButtonVCTouristEndPage: String {
            return LocalizedString(key: "9lY", originalKey: "Lark_UserGrowth_ButtonVCTouristEndPage")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_ButtonVCTouristEndPage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "9lY", originalKey: "Lark_UserGrowth_ButtonVCTouristEndPage", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_DescVCTouristEndPage: String {
            return LocalizedString(key: "40E", originalKey: "Lark_UserGrowth_DescVCTouristEndPage")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_DescVCTouristEndPage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "40E", originalKey: "Lark_UserGrowth_DescVCTouristEndPage", lang: __lang)
        }
        @inlinable
        static var Lark_UserGrowth_TitleVCTouristEndPage: String {
            return LocalizedString(key: "qII", originalKey: "Lark_UserGrowth_TitleVCTouristEndPage")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_UserGrowth_TitleVCTouristEndPage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qII", originalKey: "Lark_UserGrowth_TitleVCTouristEndPage", lang: __lang)
        }
    }
}
// swiftlint:enable all
