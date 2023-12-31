//
//  CoreTracker.swift
//  LarkCore
//
//  Created by liuwanlin on 2018/8/15.
//

import Foundation
import Homeric
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LKCommonsTracker

public final class CoreTracker {
    static let logger = Logger.log(CoreTracker.self, category: "Module.LarkCore.CoreTracker")
    public static func trackerEmojiLoadDuration(duration: CFTimeInterval, emojiKey: String, isLocalImage: Bool) {
        if isLocalImage {
            Tracker.post(SlardarEvent(name: Homeric.LARKW_EMOJI,
                                      metric: ["emoji_img_load_duration": duration * 1000],
                                      category: ["protocol": "file", "domain": "unknown"],
                                      extra: ["emojiKey": emojiKey]))
        } else {
            Tracker.post(SlardarEvent(name: Homeric.LARKW_EMOJI,
                                      metric: ["emoji_img_load_duration": duration * 1000],
                                      category: ["protocol": "rust", "domain": "unknown"],
                                      extra: ["emojiKey": emojiKey]))
        }
    }

    static func trackPreviewImage() {
        Tracker.post(TeaEvent(Homeric.PICBROWSER_VIEW, category: "picbrowser"))
    }

    static func trackDownloadImage() {
        Tracker.post(TeaEvent(Homeric.PICBROWSER_DOWNLOAD, category: "picbrowser"))
    }

    static func trackDownloadQrcode() {
        Tracker.post(TeaEvent(Homeric.DOWNLOAD_QRCODE, category: "chat"))
    }

    static func trackSavePic() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_KEYBOARD_SHORTCUT_CLICK, params: ["feature": "save_pic"]))
    }

    public static func trackMessageDeleteConfirm() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_DELETE_CONFIRM, category: "message"))
    }

    public static func trackMultiMessageDeleteConfirm() {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_DELETE_CONFIRM, category: "message"))
    }

    public static func trackMessageDelete() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_DELETE, category: "message"))
    }

    public static func trackMultiMessageDelete() {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_DELETE_CLICK, category: "message"))
    }

    // 上传头像
    class func trackUploadAvatar() {
        Tracker.post(TeaEvent(Homeric.UPLOAD_AVATAR, category: "profile"))
    }

    public static func trackImageEditEvent(_ event: String, params: [String: Any]?) {
        Tracker.post(TeaEvent(event, params: params ?? [:]))
    }

    static func picBrowserInChatHistory() {
        Tracker.post(TeaEvent(Homeric.PICBROWSER_VIEW_CHATHISTORY))
    }

    static func picBowserPrevious(fromWhere: PreviewImagesFromWhere) {
        switch fromWhere {
        case .chatHistory:
            Tracker.post(TeaEvent(Homeric.PICBROWSER_PREVIOUS_CHATHISTORY))
        case .other:
            Tracker.post(TeaEvent(Homeric.PICBROWSER_PREVIOUS))
        }
    }

    static func picBowserNext(fromWhere: PreviewImagesFromWhere) {
        switch fromWhere {
        case .chatHistory:
            Tracker.post(TeaEvent(Homeric.PICBROWSER_NEXT_CHATHISTORY))
        case .other:
            Tracker.post(TeaEvent(Homeric.PICBROWSER_NEXT))
        }
    }

    static func picBowserGoChatInChatHistory() {
        Tracker.post(TeaEvent(Homeric.PICBROWSER_VIEW_IN_CHAT))
    }

    /// 进入画板入口埋点
    public static func trackCanvasEntrance(chatModel: Chat?, isComposePost: Bool, replyMessage: Message?) {
        guard let chatModel = chatModel else {
            Self.logger.error("发送进入画板埋点时 chatModel 为空")
            return
        }
        let windowType: String
        if isComposePost {
            if chatModel.chatMode == .threadV2 && replyMessage == nil {
                // 使用 compose post 组件时，在话题页发帖(replyMessage == nil)算 channel，在富文本算 rich
                windowType = "channel"
            } else {
                windowType = "rich"
            }
        } else {
            if chatModel.type == .p2P {
                if chatModel.isSingleBot {
                    windowType = "bot"
                } else if chatModel.isOncall {
                    windowType = "helpdesk"
                } else {
                    windowType = "single"
                }
            } else {
                if chatModel.chatMode == .threadV2 {
                    windowType = "channel"
                } else if chatModel.isMeeting {
                    windowType = "meeting"
                } else if chatModel.isOncall {
                    windowType = "helpdesk"
                } else {
                    windowType = "group"
                }
            }
        }
        Tracker.post(TeaEvent(Homeric.PUBLIC_WHITEBOARD_CLICK, params: ["windowtype": windowType]))
    }
}

extension CoreTracker {
    static func imGroupMemberClick(chat: Chat,
                                   myUserId: String,
                                   isOwner: Bool,
                                   isAdmin: Bool,
                                   clickEvent: GroupMemberClickEvent,
                                   target: String) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_CLICK,
                              params: ["chat_id": chat.id,
                                       "click": clickEvent.rawValue,
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isPublic ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue,
                                       "target": target
                              ]))
    }

    static func imGroupConfirmView(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, confirmType: String) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_CONFIRM_VIEW,
                              params: ["chat_id": chat.id,
                                       "click": confirmType,
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isPublic ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue,
                                       "confirm_type": confirmType
                              ]))
    }

    static func imGroupConfirmClick(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, confirmType: String) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_CONFIRM_CLICK,
                              params: ["chat_id": chat.id,
                                       "click": "confirm",
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isPublic ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue,
                                       "confirm_type": confirmType,
                                       "target": "none"
                              ]))
    }
}
