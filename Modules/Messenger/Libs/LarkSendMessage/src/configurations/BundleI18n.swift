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
"Lark_Chat_VideoBitRateExceedLimitAttach":{
"hash":"nTA",
"#vars":0
},
"Lark_Chat_VideoBitRateExceedLimitCancel":{
"hash":"B5g",
"#vars":0
},
"Lark_Chat_VideoFileExceedsNumMBAttachment":{
"hash":"MKI",
"#vars":1,
"normal_vars":["num"]
},
"Lark_Chat_VideoFileExceedsNumMBCantSent":{
"hash":"q30",
"#vars":1,
"normal_vars":["num"]
},
"Lark_Chat_VideoFrameRateExceedLimitAttach":{
"hash":"xFE",
"#vars":0
},
"Lark_Chat_VideoFrameRateExceedLimitCancel":{
"hash":"Xvk",
"#vars":0
},
"Lark_Chat_VideoLongerNumMinAttachment":{
"hash":"eec",
"#vars":1,
"normal_vars":["num"]
},
"Lark_Chat_VideoLongerNumMinCantSent":{
"hash":"iHA",
"#vars":1,
"normal_vars":["num"]
},
"Lark_Chat_VideoResolutionExceedLimitAttach":{
"hash":"ESk",
"#vars":0
},
"Lark_Chat_VideoResolutionExceedLimitCancel":{
"hash":"i4E",
"#vars":0
},
"Lark_Chat_iCloudMediaUploadError":{
"hash":"ZI0",
"#vars":0
},
"Lark_File_ToastSingleFileSizeLimit":{
"hash":"UW8",
"#vars":1,
"normal_vars":["max_single_size"]
},
"Lark_IMVideo_InvalidVideoFormatSentAsFile_PopupText":{
"hash":"cHs",
"#vars":0
},
"Lark_IMVideo_InvalidVideoFormatUnableToSend_Text":{
"hash":"dBo",
"#vars":0
},
"Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast":{
"hash":"Lzs",
"#vars":1,
"normal_vars":["type"]
},
"Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1":{
"hash":"/Ew",
"#vars":1,
"normal_vars":["type"]
},
"Lark_IM_InsufficientStorageUnableToSendImage_Variable":{
"hash":"1c4",
"#vars":0
},
"Lark_IM_InsufficientStorageUnableToSendVideo_Variable":{
"hash":"Gvk",
"#vars":0
},
"Lark_Legacy_ComposePostVideoReadDataError":{
"hash":"V0E",
"#vars":0
},
"Lark_Legacy_Hint":{
"hash":"4L8",
"#vars":0
},
"Lark_Legacy_LarkConfirm":{
"hash":"dqw",
"#vars":0
},
"Lark_Legacy_VideoMessagePrepareToSend":{
"hash":"g/k",
"#vars":0
},
"Lark_Legacy_VideoMessageVideoUnavailable":{
"hash":"u/4",
"#vars":0
}
},
"name":"LarkSendMessage",
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
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkSendMessageAutoBundle, moduleName: "LarkSendMessage", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkSendMessageAutoBundle, moduleName: "LarkSendMessage", lang: lang) ?? key
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
    final class LarkSendMessage {
        @inlinable
        static var Lark_Chat_VideoBitRateExceedLimitAttach: String {
            return LocalizedString(key: "nTA", originalKey: "Lark_Chat_VideoBitRateExceedLimitAttach")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoBitRateExceedLimitAttach(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "nTA", originalKey: "Lark_Chat_VideoBitRateExceedLimitAttach", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_VideoBitRateExceedLimitCancel: String {
            return LocalizedString(key: "B5g", originalKey: "Lark_Chat_VideoBitRateExceedLimitCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoBitRateExceedLimitCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "B5g", originalKey: "Lark_Chat_VideoBitRateExceedLimitCancel", lang: __lang)
        }
        @inlinable
        static var __Lark_Chat_VideoFileExceedsNumMBAttachment: String {
            return LocalizedString(key: "MKI", originalKey: "Lark_Chat_VideoFileExceedsNumMBAttachment")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoFileExceedsNumMBAttachment(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Chat_VideoFileExceedsNumMBAttachment(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Chat_VideoFileExceedsNumMBAttachment(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "MKI", originalKey: "Lark_Chat_VideoFileExceedsNumMBAttachment", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var __Lark_Chat_VideoFileExceedsNumMBCantSent: String {
            return LocalizedString(key: "q30", originalKey: "Lark_Chat_VideoFileExceedsNumMBCantSent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoFileExceedsNumMBCantSent(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Chat_VideoFileExceedsNumMBCantSent(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Chat_VideoFileExceedsNumMBCantSent(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "q30", originalKey: "Lark_Chat_VideoFileExceedsNumMBCantSent", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var Lark_Chat_VideoFrameRateExceedLimitAttach: String {
            return LocalizedString(key: "xFE", originalKey: "Lark_Chat_VideoFrameRateExceedLimitAttach")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoFrameRateExceedLimitAttach(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "xFE", originalKey: "Lark_Chat_VideoFrameRateExceedLimitAttach", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_VideoFrameRateExceedLimitCancel: String {
            return LocalizedString(key: "Xvk", originalKey: "Lark_Chat_VideoFrameRateExceedLimitCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoFrameRateExceedLimitCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Xvk", originalKey: "Lark_Chat_VideoFrameRateExceedLimitCancel", lang: __lang)
        }
        @inlinable
        static var __Lark_Chat_VideoLongerNumMinAttachment: String {
            return LocalizedString(key: "eec", originalKey: "Lark_Chat_VideoLongerNumMinAttachment")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoLongerNumMinAttachment(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Chat_VideoLongerNumMinAttachment(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Chat_VideoLongerNumMinAttachment(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "eec", originalKey: "Lark_Chat_VideoLongerNumMinAttachment", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var __Lark_Chat_VideoLongerNumMinCantSent: String {
            return LocalizedString(key: "iHA", originalKey: "Lark_Chat_VideoLongerNumMinCantSent")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoLongerNumMinCantSent(_ num: Any, lang __lang: Lang? = nil) -> String {
          return Lark_Chat_VideoLongerNumMinCantSent(num: `num`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_Chat_VideoLongerNumMinCantSent(num: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "iHA", originalKey: "Lark_Chat_VideoLongerNumMinCantSent", lang: __lang)
            template = template.replacingOccurrences(of: "{{num}}", with: "\(`num`)")
            return template
        }
        @inlinable
        static var Lark_Chat_VideoResolutionExceedLimitAttach: String {
            return LocalizedString(key: "ESk", originalKey: "Lark_Chat_VideoResolutionExceedLimitAttach")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoResolutionExceedLimitAttach(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ESk", originalKey: "Lark_Chat_VideoResolutionExceedLimitAttach", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_VideoResolutionExceedLimitCancel: String {
            return LocalizedString(key: "i4E", originalKey: "Lark_Chat_VideoResolutionExceedLimitCancel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_VideoResolutionExceedLimitCancel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "i4E", originalKey: "Lark_Chat_VideoResolutionExceedLimitCancel", lang: __lang)
        }
        @inlinable
        static var Lark_Chat_iCloudMediaUploadError: String {
            return LocalizedString(key: "ZI0", originalKey: "Lark_Chat_iCloudMediaUploadError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_iCloudMediaUploadError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZI0", originalKey: "Lark_Chat_iCloudMediaUploadError", lang: __lang)
        }
        @inlinable
        static var __Lark_File_ToastSingleFileSizeLimit: String {
            return LocalizedString(key: "UW8", originalKey: "Lark_File_ToastSingleFileSizeLimit")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_File_ToastSingleFileSizeLimit(_ max_single_size: Any, lang __lang: Lang? = nil) -> String {
          return Lark_File_ToastSingleFileSizeLimit(max_single_size: `max_single_size`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_File_ToastSingleFileSizeLimit(max_single_size: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "UW8", originalKey: "Lark_File_ToastSingleFileSizeLimit", lang: __lang)
            template = template.replacingOccurrences(of: "{{max_single_size}}", with: "\(`max_single_size`)")
            return template
        }
        @inlinable
        static var Lark_IMVideo_InvalidVideoFormatSentAsFile_PopupText: String {
            return LocalizedString(key: "cHs", originalKey: "Lark_IMVideo_InvalidVideoFormatSentAsFile_PopupText")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IMVideo_InvalidVideoFormatSentAsFile_PopupText(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "cHs", originalKey: "Lark_IMVideo_InvalidVideoFormatSentAsFile_PopupText", lang: __lang)
        }
        @inlinable
        static var Lark_IMVideo_InvalidVideoFormatUnableToSend_Text: String {
            return LocalizedString(key: "dBo", originalKey: "Lark_IMVideo_InvalidVideoFormatUnableToSend_Text")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IMVideo_InvalidVideoFormatUnableToSend_Text(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "dBo", originalKey: "Lark_IMVideo_InvalidVideoFormatUnableToSend_Text", lang: __lang)
        }
        @inlinable
        static var __Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast: String {
            return LocalizedString(key: "Lzs", originalKey: "Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(_ type: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(type: `type`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(type: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "Lzs", originalKey: "Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast", lang: __lang)
            template = template.replacingOccurrences(of: "{{type}}", with: "\(`type`)")
            return template
        }
        @inlinable
        static var __Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1: String {
            return LocalizedString(key: "/Ew", originalKey: "Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(_ type: Any, lang __lang: Lang? = nil) -> String {
          return Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(type: `type`, lang: __lang)
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        static func Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(type: Any, lang __lang: Lang? = nil) -> String {
            var template = LocalizedString(key: "/Ew", originalKey: "Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1", lang: __lang)
            template = template.replacingOccurrences(of: "{{type}}", with: "\(`type`)")
            return template
        }
        @inlinable
        static var Lark_IM_InsufficientStorageUnableToSendImage_Variable: String {
            return LocalizedString(key: "1c4", originalKey: "Lark_IM_InsufficientStorageUnableToSendImage_Variable")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_InsufficientStorageUnableToSendImage_Variable(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "1c4", originalKey: "Lark_IM_InsufficientStorageUnableToSendImage_Variable", lang: __lang)
        }
        @inlinable
        static var Lark_IM_InsufficientStorageUnableToSendVideo_Variable: String {
            return LocalizedString(key: "Gvk", originalKey: "Lark_IM_InsufficientStorageUnableToSendVideo_Variable")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_IM_InsufficientStorageUnableToSendVideo_Variable(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Gvk", originalKey: "Lark_IM_InsufficientStorageUnableToSendVideo_Variable", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ComposePostVideoReadDataError: String {
            return LocalizedString(key: "V0E", originalKey: "Lark_Legacy_ComposePostVideoReadDataError")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ComposePostVideoReadDataError(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "V0E", originalKey: "Lark_Legacy_ComposePostVideoReadDataError", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_Hint: String {
            return LocalizedString(key: "4L8", originalKey: "Lark_Legacy_Hint")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_Hint(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4L8", originalKey: "Lark_Legacy_Hint", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_LarkConfirm: String {
            return LocalizedString(key: "dqw", originalKey: "Lark_Legacy_LarkConfirm")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_LarkConfirm(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "dqw", originalKey: "Lark_Legacy_LarkConfirm", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_VideoMessagePrepareToSend: String {
            return LocalizedString(key: "g/k", originalKey: "Lark_Legacy_VideoMessagePrepareToSend")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_VideoMessagePrepareToSend(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "g/k", originalKey: "Lark_Legacy_VideoMessagePrepareToSend", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_VideoMessageVideoUnavailable: String {
            return LocalizedString(key: "u/4", originalKey: "Lark_Legacy_VideoMessageVideoUnavailable")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_VideoMessageVideoUnavailable(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "u/4", originalKey: "Lark_Legacy_VideoMessageVideoUnavailable", lang: __lang)
        }
    }
}
// swiftlint:enable all
