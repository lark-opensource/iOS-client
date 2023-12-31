//
//  WebTrackUtil.swift
//  Lark
//
//  Created by liuwanlin on 2018/7/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsTracker

public final class DocTrackUtil {
    static func trackTabMalaita() {
        Tracker.post(TeaEvent("malaita_view", category: "malaita"))
    }

    static func trackView() {
        Tracker.post(TeaEvent("appcenter_view"))
    }

    static func trackEnterDoc() {
        Tracker.post(TeaEvent("chat_view",
                              category: "chat",
                              params: ["chat_type": "doc"])
        )
    }

    static func trackDocsTab() {
        Tracker.post(TeaEvent("docs_tab_view"))
    }

    static func trackChatAnnouncementNotify(edited: Bool) {
        Tracker.post(TeaEvent("announcement_notify", params: ["is_edited": edited]))
    }
}
