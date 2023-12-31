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
"Common_G_FromView_CancelButton":{
"hash":"G6E"
},
"Common_G_FromView_ConfirmButton":{
"hash":"weE"
},
"Common_G_FromView_CopyLink":{
"hash":"h9Q"
},
"Common_G_FromView_LinkCopied":{
"hash":"37M"
},
"Common_G_FromView_OperationFailedCodePercentAt":{
"hash":"SQE"
},
"Common_G_FromView_Refresh":{
"hash":"M48"
},
"Common_G_FromView_ShareToChat":{
"hash":"FWc"
},
"Common_G_Player_Live_Label":{
"hash":"w0U"
},
"Common_M_ImageErrorTryAgainLater_Toast":{
"hash":"VyE"
}
},
"name":"LarkLive",
"short_key":true,
"config":{
"mapping":{
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
"projectId":2176,
"namespaceId":[34629,41969,41970]
}]
}
}
---Meta---
*/

import Foundation
import LarkLocalizations

class BundleI18n: LanguageManager {
    private static let _tableLock = DispatchSemaphore(value: 1)
    private static var _tableMap: [String: String] = {
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name("preferLanguageChangeNotification"),
            object: nil,
            queue: nil
        ) { (_) -> Void in
            _tableLock.wait();
            defer { _tableLock.signal() }
            BundleI18n._tableMap = [:]
        }
        return [:]
    }()
    @usableFromInline
    static func LocalizedString(key: String, originalKey: String, lang: Lang? = nil) -> String {
        func fetch() -> String {
            #if USE_BASE_IMP
                #if USE_DYNAMIC_RESOURCE
                return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkLiveAutoBundle, moduleName: "LarkLive", lang: lang) ?? key
                #else 
                return self.localizedString(key: key, bundle: BundleConfig.LarkLiveAutoBundle, moduleName: "LarkLive", lang: lang) ?? key
                #endif
            #else
            let bundle = BundleConfig.LarkLiveAutoBundle
            let table = lang?.languageIdentifier ?? tableName
            let value = "\0"

            var str = NSLocalizedString(key, tableName: table, bundle: bundle, value: value, comment: "")
            if value == str && table.count > 2 {
                str = NSLocalizedString(key, tableName: String(table[..<table.index(table.startIndex, offsetBy: 2)]), bundle: bundle, value: value, comment: "")
            }
            if value == str && table != "en-US" {
                str = NSLocalizedString(key, tableName: "en-US", bundle: bundle, value: value, comment: "")
            }
            if value == str { str = key }
            return str
            #endif
        }

        if lang != nil { return fetch() } // speicify lang will no cache, call api directly
        _tableLock.wait(); defer { _tableLock.signal() }
        if let str = _tableMap[key] { return str }
        let str = fetch()
        _tableMap[key] = str
        return str
    }

    /*
     * you can set I18n like that:
     * static var done: String { @inline(__always) get { return LocalizedString(key: "done") } }
     */
    class LarkLive {
        @inlinable
        static var Common_G_FromView_CancelButton: String {
            return LocalizedString(key: "G6E", originalKey: "Common_G_FromView_CancelButton")
        }
        @inlinable
        static func Common_G_FromView_CancelButton(lang: Lang? = nil) -> String {
            return LocalizedString(key: "G6E", originalKey: "Common_G_FromView_CancelButton", lang: lang)
        }
        @inlinable
        static var Common_G_FromView_ConfirmButton: String {
            return LocalizedString(key: "weE", originalKey: "Common_G_FromView_ConfirmButton")
        }
        @inlinable
        static func Common_G_FromView_ConfirmButton(lang: Lang? = nil) -> String {
            return LocalizedString(key: "weE", originalKey: "Common_G_FromView_ConfirmButton", lang: lang)
        }
        @inlinable
        static var Common_G_FromView_CopyLink: String {
            return LocalizedString(key: "h9Q", originalKey: "Common_G_FromView_CopyLink")
        }
        @inlinable
        static func Common_G_FromView_CopyLink(lang: Lang? = nil) -> String {
            return LocalizedString(key: "h9Q", originalKey: "Common_G_FromView_CopyLink", lang: lang)
        }
        @inlinable
        static var Common_G_FromView_LinkCopied: String {
            return LocalizedString(key: "37M", originalKey: "Common_G_FromView_LinkCopied")
        }
        @inlinable
        static func Common_G_FromView_LinkCopied(lang: Lang? = nil) -> String {
            return LocalizedString(key: "37M", originalKey: "Common_G_FromView_LinkCopied", lang: lang)
        }
        @inlinable
        static var Common_G_FromView_OperationFailedCodePercentAt: String {
            return LocalizedString(key: "SQE", originalKey: "Common_G_FromView_OperationFailedCodePercentAt")
        }
        @inlinable
        static func Common_G_FromView_OperationFailedCodePercentAt(lang: Lang? = nil) -> String {
            return LocalizedString(key: "SQE", originalKey: "Common_G_FromView_OperationFailedCodePercentAt", lang: lang)
        }
        @inlinable
        static var Common_G_FromView_Refresh: String {
            return LocalizedString(key: "M48", originalKey: "Common_G_FromView_Refresh")
        }
        @inlinable
        static func Common_G_FromView_Refresh(lang: Lang? = nil) -> String {
            return LocalizedString(key: "M48", originalKey: "Common_G_FromView_Refresh", lang: lang)
        }
        @inlinable
        static var Common_G_FromView_ShareToChat: String {
            return LocalizedString(key: "FWc", originalKey: "Common_G_FromView_ShareToChat")
        }
        @inlinable
        static func Common_G_FromView_ShareToChat(lang: Lang? = nil) -> String {
            return LocalizedString(key: "FWc", originalKey: "Common_G_FromView_ShareToChat", lang: lang)
        }
        @inlinable
        static var Common_G_Player_Live_Label: String {
            return LocalizedString(key: "w0U", originalKey: "Common_G_Player_Live_Label")
        }
        @inlinable
        static func Common_G_Player_Live_Label(lang: Lang? = nil) -> String {
            return LocalizedString(key: "w0U", originalKey: "Common_G_Player_Live_Label", lang: lang)
        }
        @inlinable
        static var Common_M_ImageErrorTryAgainLater_Toast: String {
            return LocalizedString(key: "VyE", originalKey: "Common_M_ImageErrorTryAgainLater_Toast")
        }
        @inlinable
        static func Common_M_ImageErrorTryAgainLater_Toast(lang: Lang? = nil) -> String {
            return LocalizedString(key: "VyE", originalKey: "Common_M_ImageErrorTryAgainLater_Toast", lang: lang)
        }
    }
}
// swiftlint:enable all
