//
//  MessageTranslateFeedBackTracker.swift
//  LarkChat
//
//  Created by bytedance on 2020/9/11.
//

import Foundation
import UIKit
import LKCommonsTracker
import Homeric
import LarkModel

final class MessageTranslateFeedbackTracker: NSObject {

    /// 翻译反馈展示
    static func translateFeedbackView(messageID: Any? = nil,
                                      messageType: Any? = nil,
                                      srcLanguage: Any? = nil,
                                      trgLanguage: Any? = nil,
                                      cardSource: Any? = nil,
                                      fromType: Any? = nil) {
        var params: [AnyHashable: Any] = [:]
        params["message_id"] = messageID ?? ""
        params["message_type"] = messageType ?? ""
        params["src_language"] = srcLanguage ?? ""
        params["tgt_language"] = trgLanguage ?? ""
        /// cardSource值列举：im_card, doc_feed, doc_web, app_schedule, moments, unknow
        params["card_source"] = cardSource ?? "unknown"
        params["from_type"] = fromType ?? ""
        Tracker.post(TeaEvent(Homeric.ASL_TRANSLATION_FEEDBACK_VIEW, params: params))
    }

    /// 翻译反馈点击事件
    static func translateFeedbackClick(messageID: Any? = nil,
                                       messageType: Any? = nil,
                                       srcLanguage: Any? = nil,
                                       trgLanguage: Any? = nil,
                                       cardSource: Any? = nil,
                                       fromType: Any? = nil,
                                       clickType: Any? = nil,
                                       extraParam: [String: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["message_id"] = messageID ?? ""
        params["message_type"] = messageType ?? ""
        params["src_language"] = srcLanguage ?? ""
        params["tgt_language"] = trgLanguage ?? ""
        /// cardSource值列举：im_card, doc_feed, doc_web, app_schedule, moments, unknow
        params["card_source"] = cardSource ?? "unknown"
        params["from_type"] = fromType
        params["click"] = clickType
        extraParam.forEach({ (key: String, value: Any) in
            params[key] = value
        })
        Tracker.post(TeaEvent(Homeric.ASL_TRANSLATION_FEEDBACK_CLICK, params: params))
    }
}
