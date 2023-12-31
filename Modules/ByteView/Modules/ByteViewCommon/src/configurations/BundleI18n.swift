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
"View_VM_Unknown":{
"hash":"ido"
}
},
"name":"ByteViewCommon",
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
"projectId":2103,
"namespaceId":[34191]
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
                return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.ByteViewCommonAutoBundle, moduleName: "ByteViewCommon", lang: lang) ?? key
                #else 
                return self.localizedString(key: key, bundle: BundleConfig.ByteViewCommonAutoBundle, moduleName: "ByteViewCommon", lang: lang) ?? key
                #endif
            #else
            let bundle = BundleConfig.ByteViewCommonAutoBundle
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
    class ByteViewCommon {
        @inlinable
        static var View_VM_Unknown: String {
            return LocalizedString(key: "ido", originalKey: "View_VM_Unknown")
        }
        @inlinable
        static func View_VM_Unknown(lang: Lang? = nil) -> String {
            return LocalizedString(key: "ido", originalKey: "View_VM_Unknown", lang: lang)
        }
    }
}
// swiftlint:enable all
