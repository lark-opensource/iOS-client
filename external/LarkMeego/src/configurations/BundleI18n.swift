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
"Meego_Shared_MobileCommon_NewFeaturePleaseUpdateAppPopUp_GotItButton":{
"hash":"iKw"
},
"Meego_Shared_Mobile_MeegoOpenWebPage":{
"hash":"2mk"
},
"Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState":{
"hash":"nZw",
"icu_vars":["APP_DISPLAY_NAME"]
}
},
"name":"LarkMeego",
"short_key":true,
"fetch":{
"resources":[{
"projectId":13792,
"namespaceId":[64424]
}],
"locale":["en-US","zh-CN","ja-JP"]
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkMeegoAutoBundle, moduleName: "LarkMeego", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkMeegoAutoBundle, moduleName: "LarkMeego", lang: lang) ?? key
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
    final class LarkMeego {
        @inlinable
        static var Meego_Shared_MobileCommon_NewFeaturePleaseUpdateAppPopUp_GotItButton: String {
            return LocalizedString(key: "iKw", originalKey: "Meego_Shared_MobileCommon_NewFeaturePleaseUpdateAppPopUp_GotItButton")
        }
        @inlinable
        static func Meego_Shared_MobileCommon_NewFeaturePleaseUpdateAppPopUp_GotItButton(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iKw", originalKey: "Meego_Shared_MobileCommon_NewFeaturePleaseUpdateAppPopUp_GotItButton", lang: __lang)
        }
        @inlinable
        static var Meego_Shared_Mobile_MeegoOpenWebPage: String {
            return LocalizedString(key: "2mk", originalKey: "Meego_Shared_Mobile_MeegoOpenWebPage")
        }
        @inlinable
        static func Meego_Shared_Mobile_MeegoOpenWebPage(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "2mk", originalKey: "Meego_Shared_Mobile_MeegoOpenWebPage", lang: __lang)
        }
        @inlinable
        static var __Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState: String {
            return LocalizedString(key: "nZw", originalKey: "Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState")
        }
        static func Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState(lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "nZw", originalKey: "Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState", lang: __lang)
            let args: [String: ICUFormattable] = [
              "APP_DISPLAY_NAME": .string(LanguageManager.bundleDisplayName),
            ]
            do {
                template = try LanguageManager.format(lang: __lang ?? LanguageManager.currentLanguage, pattern: template, args: args)
            } catch {
                assertionFailure("Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState icu format with error: \(error)")
            }
            return template
        }
    }
}
// swiftlint:enable all
