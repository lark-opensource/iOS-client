//
//  FeedCellTrack.swift
//  LarkFeedPlugin
//
//  Created by 袁平 on 2020/7/16.
//

import Foundation
import Homeric
import LKCommonsTracker
import RustPB
import LarkPerf
import LarkModel
import LarkCore

final class FeedCellTrack {
    /// 会话盒子里面的Cell跳转Chat
    static func trackViewChatInChatbox(_ preview: FeedPreview) {
        let parentCardID = Int(preview.basicMeta.parentCardID) ?? 0
        // 只有会话盒子里的Cell跳转Chat才会打点
        guard parentCardID > 0 else { return }
        Tracker.post(TeaEvent(Homeric.CHATVIEW_CHATBOX,
                              params: ["chat_type": getChatSubType(from: preview),
                                       "access_from": "feed"]))
    }

    /// 进Chat
    static func trackChatClick(_ chatId: String) {
        ClientPerf.shared.singleEvent("feed router to chat",
                                      params: ["chatId": chatId],
                                      cost: nil)
    }

    private static func getChatSubType(from preview: FeedPreview) -> String {
        switch preview.basicMeta.feedPreviewPBType {
        case .chat:
            if preview.preview.chatData.isMeeting {
                return "meeting"
            } else {
                if preview.preview.chatData.chatterType == .bot {
                    return "single_bot"
                }
                switch preview.preview.chatData.chatType {
                case .group:
                    return "group"
                case .p2P:
                    return "single"
                case .topicGroup:
                    return "topicGroup"
                @unknown default:
                    return "unknown"
                }
            }
        case .myAi: return "myai"
        case .email, .emailRootDraft: return "mail"
        case .docFeed:
            switch preview.preview.docData.docType {
            case .unknown:
                return "unknown"
            case .doc:
                return "doc"
            case .sheet:
                return "sheet"
            case .bitable:
                return "bitable"
            case .mindnote:
                return "mindnote"
            case .file:
                return "file"
            case .slide:
                return "slide"
            case .docx:
                return "docx"
            case .wiki:
                return "wiki"
            case .folder:
                return "folder"
            case .catalog:
                return "catalog"
            case .slides:
                return "slides"
            case .shortcut:
                return "shortcut"
            @unknown default:
                return "unknown"
            }
        case .thread: return "thread"
        case .box: return "box"
        case .openapp: return "openapp"
        case .topic: return "topic"
        case .subscription: return "subscription"
        case .msgThread: return "msgThread"
        case .unknownEntity: return "unknown"
        @unknown default: return "unknown"
        }
    }

    /// 往标签里添加feed的点击事件
    static func trackAddItemInToLabel(id: String, feedsCount: Int) {
        Tracker.post(TeaEvent("feed_label_add_chat_click_click",
                              params: ["click": "add",
                                       "target": "none",
                                       "label_id": id,
                                       "add_chat_cnt": "\(feedsCount)"]))
    }
}
