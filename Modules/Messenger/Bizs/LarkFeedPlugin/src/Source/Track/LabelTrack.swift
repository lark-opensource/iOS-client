//
//  LabelTrack.swift
//  LarkFeedPlugin
//
//  Created by aslan on 2022/5/6.
//

import Foundation
import Homeric
import LKCommonsTracker
import RustPB
import LarkPerf
import LarkModel
import LarkCore

final class LabelTrack {
    /// 群设置页面点击标签
    static func trackChatSettingLabelClick(isEdit: Bool, chat: Chat) {
        var click = isEdit ? (chat.feedLabels.isEmpty ? "edit_label_mobile" : "label_mobile") : "create_label_mobile"
        var target = isEdit ? "feed_mobile_label_setting_view" : "feed_create_label_view"
        var params: [AnyHashable: Any] = [ "click": click, "target": target]
        if chat != nil {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }
}
