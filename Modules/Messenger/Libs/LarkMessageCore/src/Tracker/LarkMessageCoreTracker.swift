//
//  LarkMessageCoreTracker.swift
//  LarkMessageCore
//
//  Created by lizhiqiang on 2019/10/26.
//

import Foundation
import Homeric
import LarkModel
import LKCommonsTracker
import LarkCore
import LarkKeyboardView
import LarkAssetsBrowser
import RustPB
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsLogging
import LarkContainer
import LarkSearchCore

/// 从什么地方点击进入的详情页
public enum ShowDetailType {
    /// 消息底部'x条回复'
    case replyCount
    /// 消息头部'回复区域'
    case parentMessage
}

open class LarkMessageCoreTracker {
    static func trackTapBlock(userID: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_BLOCK,
                              params: ["source": "im_block",
                                       "to_user_id": userID],
                              md5AllowList: ["to_user_id"]))
    }

    public static func trackShowMessageDetail(type: ShowDetailType) {
        let source = type == .replyCount ? "replyCount" : "parentMessage"
        Tracker.post(TeaEvent(Homeric.THREAD_DETAIL_PAGE_ACTIVATED_INCHAT, params: ["source": source,
                                                                                    "chat_mode": "classic"]))
    }

    public static func trackEnterChat(chat: LarkModel.Chat, from: String? = nil, threadID: String? = nil) {
        var params: [String: Any] = [
            "chat_type": chat.type.rawValue,
            "chat_id": chat.id,
            "unread_start": chat.messagePosition == .recentLeft ? "first" : "last",
            "notice_setting": chat.isRemind ? "notice" : "mute"]
        if let from = from {
            params["from"] = from
        }
        if let threadID = threadID {
            params["thread_id"] = threadID
        }
        params.merge(chat.trackTypeInfo, uniquingKeysWith: { (first, _) in first })
        Tracker.post(TeaEvent(Homeric.CHAT_VIEW, category: "chat", params: params))
    }

    public static func trackPinCardClick() {
        Tracker.post(TeaEvent(Homeric.PIN_BOT_CLICK))
    }

    public static func trackAddPin(message: LarkModel.Message, chat: Chat, isGroupOwner: Bool, isSuccess: Bool) {
        Tracker.post(TeaEvent(Homeric.PIN_ADD, params: [
            "chat_id": message.chatID,
            "chat_type": chat.trackType,
            "message_type": message.type.trackValue,
            "message_id": message.id.sha1(),
            "is_groupmaster": isGroupOwner ? "1" : "0",
            "status_code": isSuccess ? "0" : "-1",
            "is_bot_chat": chat.isSingleBot ? "true" : "false",
            "is_meeting_chat": chat.isMeeting ? "true" : "false"
            ])
        )
    }

    public static func trackAddFavourite(chat: Chat, messageID: String, messageType: Message.TypeEnum) {
        Tracker.post(TeaEvent(Homeric.FAVOURITE_ADD, params: ["location": "in_chat",
                                                              "message_id": messageID,
                                                              "message_type": messageType.trackValue,
                                                              "chat_id": chat.id,
                                                              "chat_type": chat.trackType,
                                                              "is_bot_chat": chat.isSingleBot ? "true" : "false",
                                                              "is_meeting_chat": chat.isMeeting ? "true" : "false"]))
    }

    static func trackOpenChatAnnouncementFromMessage(chatType: RustPB.Basic_V1_Chat.TypeEnum) {
        var typeStr = ""
        switch chatType {
        case .p2P:
            typeStr = "p2P"
        case .group:
            typeStr = "group"
        case .topicGroup:
            typeStr = "topicGroup"
        @unknown default:
            break
        }
        Tracker.post(TeaEvent(Homeric.ANNOUNCEMENT_VIEW, params: ["announcement_view_loacation": "message",
                                                                  "chat_type": typeStr]))
    }

    //在「会话」页，发生动作事件
    static func imChatMainClick(chat: Chat,
                                target: String,
                                click: String,
                                msgId: String,
                                hongbaoType: RedPacketType,
                                hongbaoId: String) {
        let hongbaoTypeString: String
        switch hongbaoType {
        case .exclusive:
            hongbaoTypeString = "private"
        case .groupFix:
            hongbaoTypeString = "normal"
        case .groupRandom:
            hongbaoTypeString = "random"
        case .b2CFix:
            hongbaoTypeString = "company_normal"
        case .b2CRandom:
            hongbaoTypeString = "company_random"
        @unknown default:
            hongbaoTypeString = ""
        }
       var params: [AnyHashable: Any] = ["click": click,
                                         "target": target,
                                         "msg_id": msgId,
                                         "hongbao_type": hongbaoTypeString,
                                         "hongbao_id": hongbaoId]
       params += IMTracker.Param.chat(chat)
       Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                             params: params))
    }

    /// im会话访问时长(单位：秒)
    public static func trackDurationStatus(chat: Chat?, duration: TimeInterval) {
        var params: [AnyHashable: Any] = ["duration": Int(duration.rounded())]
        if let chat = chat {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DURATION_STATUS, params: params))
    }

    // 团队公开群点击“加入群组讨论“按钮
    static func joinOpenGroupClick(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "join", "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK, params: params))
    }
}

/// 用户点击 IM 中的输入框
extension LarkMessageCoreTracker {
    public static func trackClickKeyboardInputItem(_ item: KeyboardItemKey) {
        let itemValue: String
        switch item {
        case .emotion:
            itemValue = "sticker"
        case .at:
            itemValue = "mention"
        case .more:
            itemValue = "more"
        case .voice:
            itemValue = "audio"
        case .picture:
            itemValue = "picture"
        case .compose:
            itemValue = "rich_text"
        default:
            assertionFailure("new value to be tracked")
            itemValue = ""
        }

        Tracker.post(
            TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR,
                     params: ["click_button": itemValue]
            )
        )
    }
}
/// 用户点击 IM 中输入框的富文本消息
extension LarkMessageCoreTracker {
    static func trackComposePostInputItem(_ item: KeyboardItemKey) {
        let itemValue: String
        switch item {
        case .emotion:
            itemValue = "emoji"
        case .at:
            itemValue = "mention"
        case .picture:
            itemValue = "picture"
        case .send:
            itemValue = "send"
        default:
            assertionFailure("new value to be tracked")
            itemValue = ""
        }

        Tracker.post(
            TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_RICH_TEXT,
                     params: ["click_button": itemValue]
            )
        )
    }
}

/// 用户点击 IM 中输入框的图片
extension LarkMessageCoreTracker {
    public static func trackAssetPickerSuiteClickType(_ clickType: AssetPickerSuiteClickType) {
        Tracker.post(
            TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_PIC,
                     params: ["click_button": clickType.rawValue]
            )
        )
        switch clickType {
        case .camera: PublicTracker.Camera.view()
        default: break
        }
    }
}

/// 用户点击拍照
extension LarkMessageCoreTracker {
    public static func trackTakePhoto() {
        PublicTracker.Camera.Click.takePhoto()
    }
}

/// 用户点击键盘图片预览后的事件
extension LarkMessageCoreTracker {
    public static func trackAssetPickerPreviewClickType(_ clickType: AssetPickerPreviewClickType) {
        switch clickType {
        case .origin: PublicTracker.AssetsBrowser.Click.previewClick(action: .original_image)
        case .editImage: PublicTracker.AssetsBrowser.Click.previewClick(action: .edit)
        case .editVideo: PublicTracker.AssetsBrowser.Click.previewClick(action: .videoEdit)
        case .sendImage: PublicTracker.AssetsBrowser.Click.previewClick(action: .send)
        case .previewImage: PublicTracker.AssetsBrowser.previewView()
        default: break
        }
    }
}

/// 导航栏
extension LarkMessageCoreTracker {
    static func trackNewChatSearchButton() {
        Tracker.post(TeaEvent(Homeric.CHAT_HISTORY_SIDEBAR, params: ["source": "topBarAddButton"]))
    }

    static func trackChatSetting(chat: Chat, isGroupOwner: Bool, source: String) {
        let params = [
            "chat_type": chat.trackType,
            "chat_id": chat.id,
            "source": source,
            "is_admin": isGroupOwner ? "y" : "n"
            ]
        Tracker.post(TeaEvent("chat_config_sidebar", params: params))
        Tracker.post(TeaEvent(Homeric.CLICK_TITLEBAR, params: params))
    }

    static func trackNewChatSetting(chat: Chat,
                                    isGroupOwner: Bool,
                                    source: EnterChatSettingSource) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isGroupOwner)
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        let params: [String: Any] = [
            "chat_id": chat.id,
            "source": source.rawValue,
            "member_type": memberType.rawValue,
            "chat_type": chatType.rawValue,
            "external": chat.isCrossTenant,
            "chat_mode": chatMode.rawValue
        ]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_PAGE_VIEW, params: params))
    }
}

///banner打点
extension LarkMessageCoreTracker {
    public enum NoticeBarType: String {
        case mute_noticebar
        case group_application_noticebar
        case meeting_to_normal_group_noticebar
    }

    public enum NoticeBarClickType: String {
        case meeting_to_normal_group
        case click_to_process
        case close
        var target: String {
            switch self {
            case .click_to_process:
                return "none"
            default:
                return "im_chat_main_click"
            }
        }
    }

    public static func trackNoticeBarView(chat: Chat, noticeBarType: NoticeBarType) {
        var params: [AnyHashable: Any] = ["noticebar_type": noticeBarType.rawValue]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_chat_noticebar_view", params: params))

    }

    public static func trackNoticeBarClick(chat: Chat, noticeBarType: NoticeBarType, click: NoticeBarClickType) {
        var params: [AnyHashable: Any] = ["noticebar_type": noticeBarType.rawValue,
                      "click": click.rawValue,
                      "target": click.target]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_chat_noticebar_click", params: params))
    }
    public static func trackForStableWatcher(domain: String, message: String, metricParams: [String: Any]?, categoryParams: [String: Any]?) {
        guard enablePostTrack() else { return }
        guard !domain.isEmpty, !message.isEmpty else { return }
        var realCategoryParams: [String: Any] = [
            "asl_monitor_domain": domain,
            "asl_monitor_message": message
        ]
        categoryParams?.forEach({(key, value) in
            realCategoryParams[key] = value
        })
        Tracker.post(SlardarEvent(name: "asl_watcher_event",
                                  metric: metricParams ?? [:],
                                  category: realCategoryParams,
                                  extra: [:]))
    }
    private static let logger = Logger.log(LarkMessageCoreTracker.self, category: "LarkMessageCoreTracker")
    public static func enablePostTrack() -> Bool {
        return SearchRemoteSettings.shared.enablePostStableTracker
    }
}
