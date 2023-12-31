//
//  ThreadTracker.swift
//  LarkThread
//
//  Created by shane on 2019/6/5.
//

import UIKit
import Foundation
import Homeric
import LarkCore
import LarkModel
import LarkMessageCore
import LKCommonsTracker
import LarkAccountInterface
import RustPB
import LarkMessengerInterface

final class ThreadTracker: LarkMessageCoreTracker {
    enum LocationType: String {
        case threadChat = "group"
        case threadDetail = "topic"
    }

    enum TopicDeleteLocation {
        case group
        case topic
    }

    static func trackClickReplyButton() {
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_CLICKREPLYBUTTON))
    }

    static func trackClickReactionButton() {
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_CLICKREACTIONBUTTON))
    }

    static func trackClickReplyNumButton() {
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_CLICKREPLYNUMBUTTON))
    }

    static func trackLongPressDetailCell(userID: String) {
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_DETAIL_LONGPRESS, params: ["user_id": userID]))
    }

    static func topicDelete(location: TopicDeleteLocation) {
        var locationStr = "group"
        switch location {
        case .group:
            locationStr = "group"
        case .topic:
            locationStr = "topic"
        }
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_DELETE, params: ["location": locationStr]))
    }

    static func topicDeleteMenuConfirm() {
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_DELETE_CONFIRM))
    }

    static func topicDeleteMenuCancel() {
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_DELETE))
    }

    enum TopicEnterType {
        case card
        case area
        case icon
    }
    static func topicEnter(location: TopicEnterType) {
        var loactionStr = "topic_card"
        switch location {
        case .card:
            loactionStr = "topic_card"
        case .area:
            loactionStr = "reply_area"
        case .icon:
            loactionStr = "reply_icon"
        }
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_VIEWREPLY, params: ["location": loactionStr]))
    }

    static func trackFollowTopicClick(
        isFollow: Bool,
        locationType: LocationType,
        chatId: String,
        messageId: String
        ) {

        let params = ["topic_id": messageId,
                      "chat_id": chatId,
                      "location": locationType.rawValue]
        if isFollow {
            Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_FOLLOWTOPIC_CLICK, category: "group", params: params))
        } else {
            Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_UNFOLLOWTOPIC_CLICK, category: "group", params: params))
        }
    }

    static func trackClickTitleView() {
        Tracker.post(
            TeaEvent(
                "group_topicmode_clickfrom",
                category: "group",
                params: ["location": LocationType.threadDetail.rawValue]
            )
        )
    }

    static func trackClickReplyArea() {
        Tracker.post(
            TeaEvent(
                "group_topicmode_clickreplyarea",
                category: "group"
            )
        )
    }

    /// 气泡类型
    enum TipViewType: String {
        /// 上气泡
        case up
        /// 下气泡
        case down
    }

    /// 气泡点击埋点
    static func trackTipClick(tipState: UnReadMessagesTipState,
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
        case .dismiss, .showUnReadAt:
            break
        }
    }

    static func trackSendMessage(
        messageLength: Int? = nil,
        parentMessage: LarkModel.Message,
        type: Message.TypeEnum,
        chatId: String,
        isSupportURLType: (URL) -> (Bool, type: String, token: String),
        chat: Chat?) {
        let isFirstReply = parentMessage.rootMessage?.replyCount == 0 ? "first" : "other"
        let replyMessageId = parentMessage.rootMessage?.id ?? ""
        let replyMessageTime = parentMessage.rootMessage?.createTime ?? 0
        var params: [String: Any] = ["topic_id": parentMessage.id,
                                     "group_id": chatId,
                                     "chatid": chatId,
                                     "message_id": parentMessage.id,
                                     "cid": parentMessage.cid,
                                     "reply_message_id": replyMessageId,
                                     "reply_message_time": replyMessageTime,
                                     "location": "topic",
                                     "message_type": parentMessage.type.rawValue,
                                     "message_aim_type": type.trackValue,
                                     "action_position": "thread_detail_page",
                                     "notice": parentMessage.trackAtType,
                                     "reply_order": isFirstReply]

        if let length = messageLength {
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
                let result = isSupportURLType(url)
                if !result.0 { continue }
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

    static func trackMessageAdminDelete(chatID: String, locationType: LocationType) {
        Tracker.post(
            TeaEvent(
                "message_admin_delete",
                category: "message",
                params: [
                    "chatid": chatID,
                    "chat_type": locationType.rawValue
                ]
            )
        )
    }

    /// 贴主或管理员点击关闭帖子按钮
    ///
    /// - Parameters:
    ///   - chatID: String
    ///   - topicID: String
    ///   - uid: String
    static func trackTopicCloseClick(chatID: String, topicID: String, uid: String) {
        let params = [
            "chatid": chatID,
            "topicid": topicID,
            "uid": uid
        ]
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_CLOSE_CLICK, params: params))
    }

    /// 贴主或管理员点击关闭帖子按钮弹窗的确认按钮
    ///
    /// - Parameters:
    ///   - chatID: String
    ///   - topicID: String
    ///   - uid: String
    static func trackTopicCloseConfirmClick(chatID: String, topicID: String, uid: String) {
        let params = [
            "chatid": chatID,
            "topicid": topicID,
            "uid": uid
        ]
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_CLOSE_CLICK_CONFIRM, params: params))
    }

    /// 贴主或管理员点击关闭帖子按钮弹窗的取消按钮
    ///
    /// - Parameters:
    ///   - chatID: String
    ///   - topicID: String
    ///   - uid: String
    static func trackTopicCloseCancelClick(chatID: String, topicID: String, uid: String) {
        let params = [
            "chatid": chatID,
            "topicid": topicID,
            "uid": uid
        ]
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_CLOSE_CLICK_CANCEL, params: params))
    }

    /// 贴主或管理员点击重新打开帖子按钮
    ///
    /// - Parameters:
    ///   - chatID: String
    ///   - topicID: String
    ///   - uid: String
    static func trackTopicReopenClick(chatID: String, topicID: String, uid: String) {
        let params = [
            "chatid": chatID,
            "topicid": topicID,
            "uid": uid
        ]
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_REOPEN_CLICK, params: params))
    }

    /// 会话成员进入会话，因有新公告展开titlebar的次数
    ///
    /// - Parameters:
    ///   - chatID: String
    ///   - uid: String
    static func trackTopicNewAnnouncementRemind(chatID: String, uid: String) {
        let params = [
            "chatid": chatID,
            "uid": uid
        ]
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_NEWANNOUNCEMENT_REMIND, params: params))
    }

    /// 会话成员进入会话，点击新公告进入公告详情页的次数
    ///
    /// - Parameters:
    ///   - chatID: String
    ///   - uid: String
    static func trackTopicNewAnnouncementRemindClick(chatID: String, uid: String) {
        let params = [
            "chatid": chatID,
            "uid": uid
        ]
        Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_NEWANNOUNCEMENT_CLICK, params: params))
    }

    /// 在单个小组内从all切到订阅tab
    static func trackTopicAllToFollow() {
        Tracker.post(TeaEvent(Homeric.TOPIC_ALL_TO_FOLLOW))
    }

    /// 在单个小组内从订阅切到alltab
    static func trackTopicFollowToAll() {
        Tracker.post(TeaEvent(Homeric.TOPIC_FOLLOW_TO_ALL))
    }
}

/// 为了话题推荐功能新增的埋点数据。
extension ThreadTracker {
    /// 发送交互时的所在位置
    enum ThreadLocation: String {
        /// feed -> threadChat. 从Feed中进入小组时
        case threadChat = "chat"
        /// threadTab. 在动态列表中。
        case communityMoment = "community_moment"
        /// threadTab -> threadChat. 从小组Tab进入小组时
        case communityChat = "community_channel"
    }

    /// 用户交互行为类型
    enum ThreadInteractionType: String {
        case click
        case reply
        case reaction
        case follow
        case transmit
    }

    /// 记录用户在小组中发生交互行为时的特征
    ///
    /// - Parameters:
    ///   - threadID: String 话题id
    ///   - interactionType: 用户交互行为类型 click, reply, reaction, follow_topic
    ///   - impressionID: 单次拉取到的推荐序id
    ///   - positionInImpression: 该 thread 在该次 impression 中的位置
    ///   - threadLocation: 记录下Thread发送交互时的所在位置 chat_post_send, tab_relevant
    static func trackThreadUserInteraction(
        chatID: String,
        threadID: String,
        interactionType: ThreadInteractionType,
        impressionID: String?,
        positionInImpression: String = "",
        threadLocation: ThreadLocation = .threadChat) {

        var type = ""
        switch interactionType {
        case .click:
            type = "click"
        case .reaction:
            type = "reaction"
        case .follow:
            type = "follow_topic"
        case .reply:
            type = "reply"
        case .transmit:
            type = "transmit"
        }
        let params: [String: Any] = [
            "chat_id": chatID,
            "interaction_type": type,
            "thread_id": threadID,
            "impression_id": impressionID ?? "-1",
            "position_in_impression": positionInImpression,
            "thread_location": threadLocation.rawValue
        ]
        Tracker.post(TeaEvent(Homeric.THREAD_USER_INTERACTION, params: params))
    }

    /// 话题列表中当前状态下的话题情况。
    ///
    /// - Parameters:
    ///   - threadID: 话题id
    ///   - impressionID: 单次拉取到的推荐序id。默认值是"-1"
    ///   - itemHeight: 单个话题卡片总高度
    ///   - itemExposedHeight: 单个话题卡片在页面内展示的高度
    ///   - lastActiveTime: 上次用户有屏幕活跃行为的时间
    ///   - currentFastScroll: 当前是否在快速滚动，true: 是，false: 否
    ///   - threadLocation: 记录下Thread发送交互时的所在位置 chat_post_send, tab_relevant
    static func trackScreenActiveThreadSignal(
        chatID: String,
        threadID: String,
        impressionID: String? = nil,
        itemHeight: CGFloat,
        itemExposedHeight: CGFloat,
        lastActiveTime: TimeInterval,
        currentFastScroll: Bool,
        threadLocation: ThreadLocation = .threadChat
    ) {
        let params: [String: Any] = [
            "chat_id": chatID,
            "thread_id": threadID,
            "impression_id": impressionID ?? "-1",
            "item_height": itemHeight,
            "item_exposed_height": itemExposedHeight,
            "last_active_time": lastActiveTime,
            "current_fast_scroll": Int(currentFastScroll ? 1 : 0),
            "thread_location": threadLocation.rawValue
        ]

        Tracker.post(TeaEvent(Homeric.SCREEN_ACTIVE_THREAD_SIGNAL, params: params))
    }
}

extension ThreadTracker {
    enum EmotionSettingPageFrom: String {
        case fromPannel = "1"
        case fromEmotionShop = "2"
    }
    /// 表情包管理页面展示
    static func trackEmotionSettingShow(from: EmotionSettingPageFrom) {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_MANAGE,
                              params: ["stickerpack_manage_location": from.rawValue]))
    }
}

// MARK: 独立tab相关
extension ThreadTracker {
    /// 从哪里进入小组的
    enum TopicGroupEntranceType: String {
        ///从我的小组中进入小组
        case myGroups = "mygroups"
        ///从我的全部小组列表中进入
        case myAllGroups = "myallgroups"
        ///从动态页面单个卡片上的小组入口
        case momentsFeed = "moments_feed"
        ///从动态页面中的推荐小组入口进入
        case momentsRecommend = "moments_Recommend"
    }

    /// 在独立tab中进入某个默认小组
    static func trackEnterDefaultGroup(entranceType: TopicGroupEntranceType) {
        Tracker.post(TeaEvent(Homeric.GROUPS_TAB_ENTEDEFAULTRGROUP,
                              params: ["type": entranceType.rawValue]))
    }

    /// 在独立tab中进入某个小组
    static func trackEnterGroup(entranceType: TopicGroupEntranceType) {
        Tracker.post(TeaEvent(Homeric.GROUPS_TAB_ENTERGROUP,
                     params: ["type": entranceType.rawValue]))
    }
}

// MARK: 独立tab发帖相关
extension ThreadTracker {

    enum ThreadNewTopicEditAction: String {
        case send
        case cancel
    }

    static func trackNewPostEdit(action: ThreadNewTopicEditAction) {
        Tracker.post(TeaEvent(Homeric.GROUPS_TAB_NEWPOST_EDIT,
                              params: ["action": action.rawValue]))
    }

    /// 新帖
    static func trackNewPost(isDefaultTopicGroup: Bool, isPulicGroup: Bool, isAnonymous: Bool) {
        Tracker.post(
            TeaEvent(
                Homeric.CONNECT_NEW_POSTS,
                params: [
                         "group_type": isDefaultTopicGroup ? 1 : 0,
                         "channel_type": isPulicGroup ? 1 : 0,
                         "post_type": isAnonymous ? 1 : 0
                        ]
            )
        )
    }

    /// 回帖
    static func trackNewReply(isPulicGroup: Bool, isAnonymous: Bool) {
        Tracker.post(
            TeaEvent(
                Homeric.CONNECT_NEW_REPLY,
                params: [
                         "channel_type": isPulicGroup ? 1 : 0,
                         "post_type": isAnonymous ? 1 : 0
                        ]
            )
        )
    }

    static func trackUserDurationCreateContent(startTime: TimeInterval) {
        Tracker.post(
            TeaEvent(
                Homeric.CONNECT_USER_DURATION_CREATE_CONTENT,
                params: ["duration": CACurrentMediaTime() - startTime]
            )
        )
    }
}

/// reply in thread埋点
extension ThreadTracker {
    enum ReplyThreadClickType: String {
        case subscribe
        case unsubscribe
        case forward
        case mute
        case unmute
        case reply
    }

    /// 「thread详情页」页面展示
    static func trackReplyThreadView(chat: Chat,
                                     message: Message,
                                     msgCount: Int,
                                     threadId: String?,
                                     inGroup: Bool) {
        var params: [AnyHashable: Any] = ["thread_id": threadId ?? "",
                                           "msg_cnt": msgCount,
                                           "is_in_group": "true"]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_THREAD_DETAIL_VIEW, params: params))
    }
    /// 「thread详情页」页面展示
    static func trackReplyThreadClick(chat: Chat,
                                     message: Message,
                                     clickType: ReplyThreadClickType,
                                     threadId: String?,
                                     inGroup: Bool,
                                     transmitToChat: Bool = false) {
        var params: [AnyHashable: Any] = ["thread_id": threadId ?? "",
                                           "click": clickType.rawValue,
                                           "is_in_group": "true",
                                           "target": "none"]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        params += IMTracker.Param.message(message)
        if clickType == .reply {
            params += ["is_also_send_to_chat": transmitToChat.intValue]
        }
        Tracker.post(TeaEvent(Homeric.IM_THREAD_DETAIL_CLICK, params: params))
    }
}
