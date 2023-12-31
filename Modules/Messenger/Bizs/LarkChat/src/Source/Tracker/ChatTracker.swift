//
//  ChatTracker.swift
//  LarkChat
//
//  Created by liuwanlin on 2018/8/3.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import CryptoSwift
import LarkMessageCore
import LKCommonsTracker
import Homeric
import LarkMessengerInterface
import LarkSDKInterface
import RustPB
import LarkSceneManager
import LarkMessageBase
import LarkSendMessage
import LKCommonsLogging

public final class ChatTracker: LarkMessageCoreTracker {
    enum ChatType: String {
        case group
        case single
        case single_bot
        case mail
        case meeting
    }

    enum TypingLocation: String {
        case message_input
        case richtext_input
        case richtext_separate_input
        case mail_new
        case mail_reply
    }

    enum ChatAnnouncementFrom: String {
        case message
        case sidebar
    }

    static func trackSelectFace(chat: LarkModel.Chat, face: String) {
        let range = face.index(after: face.startIndex)..<face.index(before: face.endIndex)
        Tracker.post(TeaEvent(Homeric.FACE_SELECT, category: "face", params: [
            "chat_type": chat.trackType,
            "face_tag": "\(face[range])"
            ])
        )
    }

    static func trackSendMessageScene(chat: LarkModel.Chat, in vc: UIViewController) {
        if #available(iOS 13, *),
            SceneManager.shared.supportsMultipleScenes,
            let scene = vc.currentScene() {
            let sceneInfo = scene.sceneInfo
            Tracker.post(TeaEvent(Homeric.IM_MESSAGE_WINDOW, params: [
                "chat_type": chat.trackType,
                "is_aux_window": sceneInfo.isMainScene() ? "false" : "true"
                ])
            )
        }
    }

    static func typingInputActive(isFirst: Bool, chatType: ChatTracker.ChatType, location: TypingLocation) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_TYPING, params: [
            "is_first": isFirst,
            "chat_type": chatType.rawValue,
            "location": location.rawValue
            ])
        )
    }

    //点击发送附件icon
    static func trackSendAttachedFileIconClicked() {
        Tracker.post(TeaEvent(Homeric.CLICK_ATTACH_ICON, category: "driver"))
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_PLUS, params: ["click_button": "local_file"]))
    }

    //点击发送云文档icon
    public static func trackSendDocIconClicked() {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_PLUS, params: ["click_button": "cloud_file"]))
    }

    static func trackSendRedPacket(isGroupChat: Bool) {
        Tracker.post(TeaEvent(Homeric.HONGBAO_SEND, params: [
            "chat_type": isGroupChat ? "group" : "single"
            ])
        )
    }

    // 点击发送个人名片 icon
    static func trackSendUserCardIconClicked() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_USERCARD_ENTER))
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_PLUS, params: ["click_button": "usercard"]))
    }

    // 关闭个人名片中选人模块弹窗
    static func trackSendUserCardCancel() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_USERCARD_CLOSE))
    }

    // 选择名片成功并发送
    static func trackChooseUserCardSuccess(channel: String) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_USERCARD_SUCCESS, params: ["usercard_select_channel": channel]))
    }

    public static func trackEnterVote(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_VOTE_ENTER))
        Tracker.post(TeaEvent(Homeric.IM_CHAT_VOTE_CLICK, params: chat.chatInfoForTrack))
    }

    public static func sendDocInChat() {
        Tracker.post(TeaEvent(Homeric.DOCS_SEND))
    }

    static func trackImageEditEvent(_ event: String, params: [String: Any]?) {
        Tracker.post(TeaEvent(event, params: params ?? [:]))
    }

    static func trackAudioPlayDrag() {
        Tracker.post(TeaEvent(Homeric.AUDIO_PLAY_DRAG))
    }

    static func trackAtPerson(params: [String: String]) {
        Tracker.post(TeaEvent(Homeric.NOTICELIST_CHOICE, params: params))
    }

    static func trackAtAll() {
        Tracker.post(TeaEvent(
            "noticelist_choice",
            params: [
                "category": "Chat",
                "notice": "atall",
                "choiceType": "normal",
                "memberType": "internal",
                "is_query": "n",
                "search_location": "1",
                "guess_type": "invite"]))
    }

    static func trackEnterReadStatus() {
        Tracker.post(TeaEvent(Homeric.READLIST_VIEW, category: "chat"))
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

    // 进入会话设置页打点
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

    // 群分享时，「群名片」页面的展示
    static func trackImChatGroupCardView(chat: Chat, extraInfo: [AnyHashable: Any]) {
        var params = IMTracker.Param.chat(chat)
        params["group_description_length"] = chat.description.count
        params["group_name_length"] = chat.name.count
        params["member_count"] = chat.userCount
        params += extraInfo
        Tracker.post(TeaEvent(Homeric.IM_CHAT_GROUP_CARD_VIEW, params: params))
    }

    // 在「群名片」页，发生动作事件
    static func trackImChatGroupCardClick(chat: Chat, click: String, extra: [AnyHashable: Any] = [:]) {
        var params = IMTracker.Param.chat(chat)
        params["click"] = click
        params += extra

        Tracker.post(TeaEvent(Homeric.IM_CHAT_GROUP_CARD_CLICK,
                              params: params))
    }
}

// chat部分的打点
extension ChatTracker {
    static func trackMessageReply(
        parentMessage: LarkModel.Message,
        messageType: Message.TypeEnum,
        chatId: String,
        length: Int? = nil,
        actionPosition: ActionPosition,
        docSDKAPI: ChatDocDependency?,
        chat: Chat?) {
        let isFirstReply = parentMessage.rootMessage?.replyCount == 0 ? "first" : "other"
        let replyMessageId = parentMessage.rootMessage?.id ?? ""
        let replyMessageTime = parentMessage.rootMessage?.createTime ?? 0

        var params: [String: Any] = [
            "chat_id": chatId,
            "message_id": parentMessage.id,
            "cid": parentMessage.cid,
            "reply_message_id": replyMessageId,
            "reply_message_time": replyMessageTime,
            "message_type": parentMessage.type.rawValue,
            "message_aim_type": messageType.trackValue,
            "action_position": actionPosition.rawValue,
            "notice": parentMessage.trackAtType,
            "reply_order": isFirstReply
        ]

        if let length = length {
            params["message_length"] = length
        }
        if let chat = chat {
            params.merge(chat.trackTypeInfo, uniquingKeysWith: { (first, _) in first })
            params["chat_type"] = chat.type.rawValue
        }

        params["is_has_docslink"] = "n"
        var richText: RustPB.Basic_V1_RichText?
        if parentMessage.type == .text,
            let content = parentMessage.content as? TextContent {
            richText = content.richText
        } else if parentMessage.type == .post,
            let content = parentMessage.content as? PostContent {
            richText = content.richText
        }
        if let richText = richText {
            params["richtext_image_count"] = richText.imageIds.count
            let emotions = richText.elements.values.filter({ $0.tag == .emotion })
            params["emoji_type"] = emotions.map { $0.property.emotion.key }
            params["emoji_count"] = emotions.count

            var docsCount = 0
            for element in richText.elements.values {
                guard element.tag == .a else { continue }
                let text = element.property.anchor.content
                guard let url = URL(string: text) else { continue }
                guard let result = docSDKAPI?.isSupportURLType(url: url), result.0 else { continue }
                params["is_has_docslink"] = "y"
                if docsCount == 0 {
                    params["file_type"] = result.type
                    params["file_id"] = result.token
                }
                docsCount += 1
            }
            params["doc_link_count"] = docsCount
        }

        Tracker.post(TeaEvent(Homeric.MESSAGE_REPLY, category: "message", params: params, md5AllowList: ["file_id"]))
    }
}

/// Pin 相关埋点
extension ChatTracker {
    enum DeletePinLocation: Int {
        case inChat = 1
        case inChatPin = 2
    }

    static func trackDeletePin(message: LarkModel.Message, groupId: String, isGroupOwner: Bool, location: DeletePinLocation) {
        Tracker.post(TeaEvent(Homeric.PIN_CANCEL, params: [
            "the_groupid": groupId.sha1(),
            "the_message_type": message.type.trackValue,
            "the_message_id": message.id.sha1(),
            "is_groupmaster": isGroupOwner ? "1" : "0",
            "the_pin_cancel_location": "\(location.rawValue)"
            ])
        )
    }

    enum ClickPinLocation: Int {
        case inChatPin = 1
    }
    static func trackClickPin(message: LarkModel.Message, groupId: String, isGroupOwner: Bool, jumpToChat: Bool, location: ClickPinLocation = .inChatPin) {
        Tracker.post(TeaEvent(Homeric.PIN_CLICK, params: [
            "the_groupid": groupId.sha1(),
            "the_message_type": message.type.trackValue,
            "the_message_id": message.id.sha1(),
            "is_groupmaster": isGroupOwner ? "1" : "0",
            "click_sub_type": jumpToChat ? "2" : "1",
            "pin_click_location": "\(location.rawValue)"
            ])
        )
    }

    static func imUnpinConfirmView(chat: Chat) {
        //在「取消PIN确认」页面，发生动作事件(14)
        Tracker.post(TeaEvent(Homeric.IM_UNPIN_CONFIRM_VIEW, params: IMTracker.Param.chat(chat)))
    }

    static func trackPinAlertConfirm(message: LarkModel.Message, isGroupOwner: Bool, chat: Chat) {
        Tracker.post(TeaEvent(Homeric.PIN_ALERT, params: [
            "the_groupid": chat.id.sha1(),
            "the_message_type": message.type.trackValue,
            "the_message_id": message.id.sha1(),
            "is_groupmaster": isGroupOwner ? "1" : "0"
            ])
        )
        var params: [AnyHashable: Any] = [ "click": "confirm",
                                           "target": "im_chat_pin_view"]
        params += IMTracker.Param.chat(chat)
        //在「取消PIN确认」页面，发生动作事件(15)
        Tracker.post(TeaEvent(Homeric.IM_UNPIN_CONFIRM_CLICK, params: params))
    }

    static func trackPinAlertCancel(message: LarkModel.Message, isGroupOwner: Bool, chat: Chat) {
        Tracker.post(TeaEvent(Homeric.PIN_CANCEL_ALERT, params: [
            "the_groupid": chat.id.sha1(),
            "the_message_type": message.type.trackValue,
            "the_message_id": message.id.sha1(),
            "is_groupmaster": isGroupOwner ? "1" : "0"
            ])
        )
        var params: [AnyHashable: Any] = [ "click": "cancel",
                                           "target": "im_chat_pin_view"]
        params += IMTracker.Param.chat(chat)
        //在「取消PIN确认」页面，发生动作事件(16)
        Tracker.post(TeaEvent(Homeric.IM_UNPIN_CONFIRM_CLICK, params: params))
    }

    static func trackIMChatPinClickSearch(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "search",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_PIN_CLICK, params: params))
    }

    static func trackPinMoreClick() {
        Tracker.post(TeaEvent(Homeric.PIN_MORE_CLICK))
    }

    static func trackChatPinSearch() {
        Tracker.post(TeaEvent(Homeric.CHAT_PIN_SEARCH))
    }

    static func trackChatPinSearchClick() {
        Tracker.post(TeaEvent(Homeric.CHAT_PIN_SEARCH_CLICK))
    }

    static func trackChatPinSearchClear() {
        Tracker.post(TeaEvent(Homeric.CHAT_PIN_SEARCH_CLEAR))
    }

    /// 在(PIN)页面，发生动作事件(6)
    static func imChatPinClickMore(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "more",
                                           "target": "im_chat_pin_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_PIN_CLICK, params: params))
    }

    /// 在(PIN)页面，发生动作事件(10)
    static func imChatPinMoreView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_PIN_MORE_VIEW, params: IMTracker.Param.chat(chat)))
    }

    static func imChatPinMoreClickWithType(_ trackParams: [AnyHashable: Any], chat: Chat) {
        var params: [AnyHashable: Any] = trackParams
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_PIN_MORE_CLICK, params: params))
    }

    static func trackChatIMChatPinView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_PIN_VIEW, params: IMTracker.Param.chat(chat)))
    }
}

// 多选打点
extension ChatTracker {

    static func trackMultiSelectExit() {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_EXIT))
    }
}

// chat_config
extension ChatTracker {
    static func trackRemoveMemberClick() {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_REMOVE_MEMBER_CLICK))
    }

    static func trackFindMemberClick() {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_FIND_MEMBER_CLICK))
    }

}

extension ChatTracker {
    static func trackOpenChatAnnouncement(from: ChatAnnouncementFrom, chatType: RustPB.Basic_V1_Chat.TypeEnum) {
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
        Tracker.post(TeaEvent(Homeric.ANNOUNCEMENT_VIEW, params: ["announcement_view_loacation": from.rawValue,
                                                                  "chat_type": typeStr]))
    }
}

// pin
extension ChatTracker {
    static func trackPinGuideShow() {
        Tracker.post(TeaEvent(Homeric.NEW_GUIDE_PIN_MENTIONALL))
    }

    static func trackPinSidebarGuideShow() {
        Tracker.post(TeaEvent(Homeric.NEW_GUIDE_PIN_SIDEBAR))
    }

}

extension ChatTracker {
    static func trackFavouriteDelete() {
        Tracker.post(TeaEvent(Homeric.FAVOURITE_DELETE))
    }

    static func trackFavouriteForward() {
        Tracker.post(TeaEvent(Homeric.FAVOURITE_FORWARD))
    }

    static func trackShowFavoriteList() {
        Tracker.post(TeaEvent(Homeric.ICON_FAVOURITE_CLICK))
    }
}

// 定位打点
extension ChatTracker {
    static func trackLocationEnter() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION_ENTER))
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_PLUS, params: ["click_button": "location"]))
    }

    static func trackLocationSent(nameType: String, chatType: String, resultType: String) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION_SENT, params: ["name_type": nameType, "chat_type": chatType, "result_type": resultType]))
    }

    static func trackLocationMapType(type: String) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION_VIEW, params: ["navigation_map_type": type]))
    }
}

extension ChatTracker {
    /// 添加表情
    static func trackAddSticker() {
        Tracker.post(TeaEvent(Homeric.STICKER_ADD, category: "sticker"))
    }

    /// 删除表情
    static func trackDeleteSticker() {
        Tracker.post(TeaEvent(Homeric.STICKER_DELETE, category: "sticker"))
    }

    enum EmotionSettingPageFrom: String {
        case fromPannel = "1"
        case fromEmotionShop = "2"
    }
    /// 表情包管理页面展示
    static func trackEmotionSettingShow(from: EmotionSettingPageFrom) {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_MANAGE,
                              params: ["stickerpack_manage_location": from.rawValue]))
    }

    /// 发送sticker
    static func trackSendSticker(_ chatModel: LarkModel.Chat, sticker: RustPB.Im_V1_Sticker, message: Message, stickersCount: Int) {
        //tracker stickerSetID if emotion type is stickerSet
        if !sticker.stickerSetID.isEmpty {
            let info = [
                "sticker_id": sticker.stickerID,
                "stickerpack_id": sticker.stickerSetID,
                "chat_id": chatModel.id,
                "num_of_stickers": stickersCount,
                "is_bot_chat": chatModel.isSingleBot,
                "is_meeting_chat": chatModel.isMeeting,
                "chat_type": chatModel.type.rawValue] as [String: Any]
            Tracker.post(TeaEvent(Homeric.STICKERPACK_SEND, params: info))
        }

        var params: [String: Any] = [
            "chat_type": chatModel.type.rawValue,
            "stickerpack_id": sticker.stickerSetID,
            "sticker_id": sticker.stickerID,
            "chat_id": chatModel.id,
            "cid": message.cid
        ]
        params.merge(chatModel.trackTypeInfo, uniquingKeysWith: { (first, _) in first })
        Tracker.post(TeaEvent(Homeric.STICKER_SENT, category: "sticker", params: params))
    }
}

/// GroupCard
extension ChatTracker {
    /// 文档（Document）: https://bytedance.feishu.cn/docs/doccnAPlLO9ViZjgQGl5LRBtpoh#1GlLle
    enum GroupCardQRJoinType: String {
        case group = "Join_Group"
        case organization = "Join_Organization"
        case switchOrganization = "Switch_Organization"
    }

    static func trackGroupCardQRTapJoinType(_ type: GroupCardQRJoinType) {
        Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_GROUP_NOTIN_DETAIL, params: ["click_button": type.rawValue]))
    }

    /// 文档（Document）: https://bytedance.feishu.cn/docs/doccnAPlLO9ViZjgQGl5LRBtpoh#1GlLle
    static func trackGroupCardQRCanJpin(_ canJoin: Bool) {
        Tracker.post(TeaEvent(
            Homeric.SCAN_QRCODE_GROUP_NOTIN_DETAIL_JOIN_ORGANIZATION,
            params: ["page_type": canJoin ? "normal" : "no_permisson"]
        ))
    }
}

/// 已读活动红包
extension ChatTracker {
    /// 奖励消息中点击拆虚拟红包
    static func trackOpenFakeHongbao(type: String) {
        Tracker.post(TeaEvent(Homeric.CLICK_OPEN_FAKE_HONGBAO, params: ["type": type]))
    }
}

extension ChatTracker {
    static func trackMentionExternalUserSearchTime(_ time: Int, isSuccess: Bool) {
        Tracker.post(TeaEvent(
            Homeric.MENTION_EXTERNAL_USER_SEARCH_TIME,
            params: [
                "time": time,
                "status": isSuccess
            ]
        ))
    }
}

/// 群链接
extension ChatTracker {
    /// 在口令落地页点击进入群组
    static func trackChatTokenClickThrough() {
        Tracker.post(TeaEvent(Homeric.CHAT_TOKEN_CLICK_THROUGH))
    }

    /// 点击群链接进入群详情页后点击加入群组
    static func trackChatLinkClickThrough() {
        Tracker.post(TeaEvent(Homeric.CHAT_LINK_CLICK_THROUGH))
    }
}

/// 气泡类型
enum TipViewType: String {
    /// 上气泡
    case up
    /// 下气泡
    case down
}

/// @类型
enum MentionType: String {
    /// @我
    case me = "user"
    /// @所有人
    case all = "all"
}

/// 点击会话内气泡
extension ChatTracker {
    /// 气泡点击埋点
    static func trackTipClick(tipState: UnReadMessagesTipState,
                              mentionType: MentionType? = nil,
                              tipViewType: TipViewType? = nil) {
        switch tipState {
        case .showUnReadMessages(let count, _):
            if let tipViewType = tipViewType {
                let params: [String: Any] = ["unread_total": count,
                                             "chat_mode": "classic",
                                             "direction": tipViewType.rawValue]
                Tracker.post(TeaEvent(Homeric.NEW_MESSAGE_TOAST_CLICK, params: params))
            }
        case .showToLastMessage:
            Tracker.post(TeaEvent(Homeric.MESSAGE_DIALOG_BACK_TO_BOTTOM_CLICK,
                                  params: ["chat_mode": "classic"]))
        case .showUnReadAt:
            if let mentionType = mentionType, let tipViewType = tipViewType {
                let params: [String: Any] = ["type": mentionType.rawValue, "direction": tipViewType.rawValue]
                Tracker.post(TeaEvent(Homeric.NEW_MESSAGE_MENTION_CLICK, params: params))
            }
        case .dismiss:
            break
        }
    }
}

/// 地图打点
extension ChatTracker {
    /// 接收定位页面点击分享
    static func trackChatShareClick() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION_SHARE_CLICK))
    }

    /// 接收定位页面点击发起导航
    static func trackChatNavigationClick() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION_NAVIGATION_CLICK))
    }
}

/// 单向联系人打点
extension ChatTracker {
    /// 单聊IM窗口音视频屏蔽
    static func trackChatCallBlock(_ source: AddContactApplicationSource) {
        if source == .voiceCall {
            Tracker.post(TeaEvent(Homeric.CHAT_VOICECALLS_BLOCKED))
        } else if source == .videoCall {
            Tracker.post(TeaEvent(Homeric.CHAT_VIDEOCALLS_BLOCKED))
        }
    }
}

/// 详情页的打点
extension ChatTracker {
    static func trackMsgDetailView(message: Message?, chat: Chat, from_source: MessageDetailFromSource) {
        guard let message = message, !chat.isCrypto else {
            return
        }
        var params: [AnyHashable: Any] = ["from_source": from_source.rawValue, "msg_cnt": message.replyCount]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_MSG_DETAIL_VIEW, params: params))
    }
}

extension IMTracker.Chat {
    struct ChatMenu {}
}

extension IMTracker.Chat.ChatMenu {
    static func View(_ chat: Chat,
                     isAppMenu: Bool,
                     firstLayerNums: Int = 0,
                     secondLayerNums: [Int] = []) {
        var params: [AnyHashable: Any] = ["have_switch_button": "true",
                                           "menu_type": isAppMenu ? "app_menu" : "input_box"]
        if !isAppMenu {
            params += ["first_layer_nums": "0", "second_layer_nums": "0"]
        } else {
            var secondLayerNumsDic: [String: String] = [:]
            for (index, value) in secondLayerNums.enumerated() {
                secondLayerNumsDic["\(index + 1)"] = "\(value)"
            }
            params += ["first_layer_nums": "\(firstLayerNums)"]
            params += ["second_layer_nums": secondLayerNumsDic]
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_BOX_VIEW,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    static func Click(_ chat: Chat, featureButtonId: Int64) {
        var params: [AnyHashable: Any] = ["click": "feature_button",
                                           "feature_button_id": "\(featureButtonId)"]
        if chat.type == .p2P, chat.chatter?.type == .bot {
            params += ["bot_id": chat.chatterId]
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_BOX_CLICK,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

//ai 相关打点
class AIMessageShowTracker {
    private var chat: Chat?
    private let aiChatterId: String
    private var messageReadStart: [String: TimeInterval] = [:]
    private var messageParams: [String: [AnyHashable: Any]] = [:]
    private let minDuration: Int64 = 500
    private let logger = Logger.log(AIMessageShowTracker.self, category: "AIMessageShowTracker")
    init(chat: Chat?, aiChatterId: String) {
        self.chat = chat
        self.aiChatterId = aiChatterId
    }

    func startShow(messsage: Message) {
        guard self.aiChatterId == messsage.fromId, messageReadStart[messsage.id] == nil else {
            return
        }
        messageReadStart[messsage.id] = CACurrentMediaTime()
        messageParams[messsage.id] = IMTracker.Param.message(messsage)
    }

    func endShow(messsage: Message) {
        guard self.aiChatterId == messsage.fromId,
              let start = messageReadStart.removeValue(forKey: messsage.id),
              let messsageCommonParams = messageParams.removeValue(forKey: messsage.id) else {
            return
        }
        let duration = Int64((CACurrentMediaTime() - start) * 1000)
        self.trackAIMessageShow(messageId: messsage.id,
                                messsageCommonParams: messsageCommonParams,
                                duration: duration)
    }

    private func trackAIMessageShow(messageId: String, messsageCommonParams: [AnyHashable: Any], duration: Int64) {
        guard duration > minDuration else {
            return
        }
        var params: [AnyHashable: Any] = ["duration": duration,
                                          "message_id": messageId]
        if let chat = self.chat {
            params += IMTracker.Param.chat(chat)
        }
        params += messsageCommonParams
        Tracker.post(TeaEvent("public_ai_message_status",
                              params: params))
    }
}
