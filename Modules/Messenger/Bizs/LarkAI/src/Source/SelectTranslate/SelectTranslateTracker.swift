//
//  SelectTranslateTracker.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import ServerPB
import LarkSDKInterface

final class SelectTranslateTracker: NSObject {
    static func track(_ event: String, params: [String: Any]) {
        #if DEBUG
        print("track(\(event)): \(params)")
        #endif
        Tracker.post(TeaEvent(event, params: params))
    }

    /// 滑动选择翻译
    static func selectTranslateCardView(resultType: String,
                                        wordID: Any? = nil,
                                        messageID: Any? = nil,
                                        chatID: Any? = nil,
                                        fileID: Any? = nil,
                                        fileType: Any? = nil,
                                        srcLanguage: Any? = nil,
                                        tgtLanguage: Any? = nil,
                                        translateType: Any? = nil,
                                        cardSouce: Any? = nil) {
        var param: [String: Any] = [:]
        param["msg_id"] = messageID ?? ""
        param["chat_id"] = chatID ?? ""
        param["word_id"] = wordID ?? "none"
        param["src_language"] = srcLanguage ?? ""
        param["card_source"] = cardSouce ?? ""
        param["result_type"] = resultType
        param["tgt_language"] = tgtLanguage ?? ""
        param["translate_type"] = translateType ?? ""
        param["file_id"] = fileID ?? ""
        param["file_type"] = fileType ?? ""
        track(Homeric.ASL_CROSSLANG_TRANSLATION_CARD_VIEW, params: param)
    }

    static func selectTranslateCardClick(resultType: String,
                                         clickType: String,
                                         wordID: Any? = nil,
                                         messageID: Any? = nil,
                                         chatID: Any? = nil,
                                         fileID: Any? = nil,
                                         fileType: Any? = nil,
                                         srcLanguage: Any? = nil,
                                         tgtLanguage: Any? = nil,
                                         cardSouce: Any? = nil,
                                         translateType: Any? = nil,
                                         translateLength: Any? = nil,
                                         extraParam: [String: Any] = [:]) {
        var param: [String: Any] = [:]
        param["click"] = clickType
        param["msg_id"] = messageID ?? ""
        param["chat_id"] = chatID ?? ""
        param["word_id"] = wordID ?? "none"
        param["src_language"] = srcLanguage ?? ""
        param["card_source"] = cardSouce ?? ""
        param["result_type"] = resultType
        param["tgt_language"] = tgtLanguage ?? ""
        param["file_id"] = fileID ?? ""
        param["file_type"] = fileType ?? ""
        param["translate_type"] = translateType ?? ""
        param["translate_length"] = translateLength ?? 0

        extraParam.forEach({ (key: String, value: Any) in
            param[key] = value
        })
        track(Homeric.ASL_CROSSLANG_TRANSLATION_CARD_CLICK, params: param)
    }
}
