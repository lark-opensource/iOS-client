//
//  FlagTracker.swift
//  LarkFlag
//
//  Created by liuxianyu on 2022/6/2.
//

import Foundation
import LarkModel
import RustPB
import LKCommonsTracker
import Homeric
import LarkCore
import LarkMessengerInterface

public struct FlagTracker {
    struct Main {}
    struct BaseFeed {}
    struct MsgTypeFeed {}
}

extension FlagTracker.Main {
    static func Click(_ flagItem: FlagItem, _ iPadStatus: String?) {
        switch flagItem.type {
        case .feed:
            guard let preview = flagItem.feedPreview else { return }
            var click = "feed_leftclick_chat"
            var target = "im_chat_main_view"
            if preview.basicMeta.feedPreviewPBType == .docFeed {
                click = "feed_leftclick_doc"
                target = "ccm_docs_page_view"
            }
            var params: [AnyHashable: Any] = ["click": click, "target": target, "target_tab": "flag"]
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            params["is_temporary_top"] = preview.basicMeta.onTopRankTime > 0 ? 1 : 0
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))

        case .message:
            guard let messageVM = flagItem.messageVM,
                  let chat = messageVM.chat else { return }
            let message = messageVM.message
            var params: [AnyHashable: Any] = ["click": "msg_leftclick", "target": "im_chat_main_view", "target_tab": "flag", "is_ai": chat.isP2PAi]
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
    static func Swipe(_ flagItem: FlagItem, _ iPadStatus: String?) {
        switch flagItem.type {
        case .feed:
            guard flagItem.feedPreview != nil else { return }
            var params: [AnyHashable: Any] = ["click": "feed_leftslide", "target": "feed_leftslide_detail_view", "target_tab": "flag"]
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))

        case .message:
            guard let messageVM = flagItem.messageVM,
                  let chat = messageVM.chat else { return }
            let message = messageVM.message
            var params: [AnyHashable: Any] = ["click": "msg_leftslide", "target": "im_chat_main_view", "target_tab": "flag", "is_ai": chat.isP2PAi]
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

extension FlagTracker.BaseFeed {
    static func Unmark(_ flagItem: FlagItem) {
        guard flagItem.type == .feed,
              flagItem.feedPreview != nil else { return }
        let params: [AnyHashable: Any] = ["click": "unmark", "target": "none"]
        Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK, params: params))
    }
}

extension FlagTracker.MsgTypeFeed {
    static func Unmark(_ flagItem: FlagItem) {
        guard flagItem.type == .message,
              let messageVM = flagItem.messageVM,
              let chat = messageVM.chat else { return }
        let message = messageVM.message
        var params: [AnyHashable: Any] = ["click": "unmark", "target": "none"]
        params += IMTracker.Param.message(message)
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.FEED_MSG_PRESS_CLICK,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    static func Forward(_ flagItem: FlagItem) {
        guard flagItem.type == .message,
              let messageVM = flagItem.messageVM,
              let chat = messageVM.chat else { return }
        let message = messageVM.message
        var params: [AnyHashable: Any] = ["click": "forward", "target": "none"]
        params += IMTracker.Param.message(message)
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.FEED_MSG_PRESS_CLICK,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}
