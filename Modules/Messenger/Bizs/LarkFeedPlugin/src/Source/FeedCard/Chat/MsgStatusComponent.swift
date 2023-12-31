//
//  ChatFeedCardMsgStatusVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/29.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import RustPB
import UniverseDesignColor
import LarkEmotion

// MARK: - Factory
class ChatFeedCardMsgStatusFactory: FeedCardBaseComponentFactory {
    // 组件类别
    var type: FeedCardComponentType {
        return .msgStatus
    }
    init() {}

    func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return ChatFeedCardMsgStatusVM(feedPreview: feedPreview)
    }

    func creatView() -> FeedCardBaseComponentView {
        return ChatFeedCardMsgStatusComponentView()
    }
}

class ChatFeedCardMsgStatusVM: FeedCardBaseComponentVM {
    // VM 数据
    let feedPreview: FeedPreview

    // 表明组件类别
    var type: FeedCardComponentType {
        return .msgStatus
    }

    let supportHideByEvent: Bool

    var selectedStatus = false

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.feedPreview = feedPreview
        // 单聊下如果 reactions 超一屏, 则摘要需要隐藏
        self.supportHideByEvent = feedPreview.preview.chatData.chatType == .p2P
    }

    func update(selectedStatus: Bool) {
        self.selectedStatus = selectedStatus
    }

    func subscribedEventTypes() -> [FeedCardEventType] {
        return [.selected]
    }

    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .selected(let selected) = value {
            self.selectedStatus = selected
        }
    }

    var icon: UIImage? {
        // 草稿优先级最高. 如果有草稿且不是选中状态，则显示草稿
        if let icon = getDraftIcon(), !selectedStatus {
            return icon
        }
        // [特化逻辑] 定时发送失败，直接返回失败icon，因为此时最新一条消息类型不是该定时发送消息，所以不能继续执行了
        if case .failed = feedPreview.uiMeta.digestStatus {
            return Resources.LarkFeedPlugin.send_message_failed
        }
        // 根据最新一条消息类型，获取icon
        return getMsgTypeIcon(feedPreview: feedPreview)
    }

    // 获取草稿
    private func getDraftIcon() -> UIImage? {
        // 有草稿且外部指定不忽略草稿则返回草稿的 icon
        guard !feedPreview.uiMeta.draft.content.isEmpty else {
            return nil
        }
        return Resources.LarkFeedPlugin.feed_draft_icon
    }

    // 根据不同消息类型获取icon
    private func getMsgTypeIcon(feedPreview: FeedPreview) -> UIImage? {
        switch feedPreview.preview.chatData.lastMessageType {
        case .system:
            return getSystemMessageIcon(systemMessageType: feedPreview.preview.chatData.systemMessageType, isVoiceCall: feedPreview.preview.chatData.isVoiceCall)
        case .card:
            if let icon = getCardIcon(cardType: feedPreview.preview.chatData.cardType, isCrypto: feedPreview.preview.chatData.isCrypto) {
                return icon
            }
            let hasReaction = !feedPreview.uiMeta.reactions.isEmpty
            return getMsgStatusIcon(hasReaction: hasReaction, entityStatus: feedPreview.uiMeta.digestStatus)
        case .videoChat:
            return getVideoChatIcon(videoChatType: feedPreview.preview.chatData.videoChatType, isCrypto: feedPreview.preview.chatData.isCrypto)
        @unknown default:
            let hasReaction = !feedPreview.uiMeta.reactions.isEmpty
            return getMsgStatusIcon(hasReaction: hasReaction, entityStatus: feedPreview.uiMeta.digestStatus)
        }
    }

    // 根据消息发送状态获取icon
    private func getMsgStatusIcon(hasReaction: Bool, entityStatus: FeedPreviewDigestStatus) -> UIImage? {
        switch feedPreview.uiMeta.digestStatus {
        case .normal:
            return nil
        case .read:
            if hasReaction, entityStatus == .read {
                // 因为有reaction意味着别人已读你的消息，所以不需要显示已读状态
                return nil
            }
            return Resources.LarkFeedPlugin.feed_read_icon
        case .unread:
            return Resources.LarkFeedPlugin.feed_unread_icon
        case .pending:
            return Resources.LarkFeedPlugin.sending_message.ud.withTintColor(UIColor.ud.iconN3)
        case .failed:
            return Resources.LarkFeedPlugin.send_message_failed
        default:
            fatalError("Should not be here")
        }
    }

    private func getSystemMessageIcon(systemMessageType:
                                      RustPB.Basic_V1_Content.SystemType,
                                      isVoiceCall: Bool) -> UIImage? {
        switch systemMessageType {
        case .vcCallHostCancel,
             .vcCallPartiNoAnswer,
             .vcCallPartiCancel,
             .vcCallHostBusy,
             .vcCallPartiBusy,
             .vcCallFinishNotice,
             .vcCallDuration,
             .vcCallConnectFail,
             .vcCallDisconnect:
            return isVoiceCall ? Resources.LarkFeedPlugin.feed_voice_icon : Resources.LarkFeedPlugin.feed_meeting_end_icon
        case .userCallE2EeVoiceDuration,
             .userCallE2EeVoiceWhenRefused,
             .userCallE2EeVoiceOnCancell,
             .userCallE2EeVoiceOnMissing,
             .userCallE2EeVoiceWhenOccupy:
            return Resources.LarkFeedPlugin.feed_encryptied_icon
        case .vcMeetingStarted,
             .vcVideoChatStarted:
            return Resources.LarkFeedPlugin.feed_meeting_start_icon
        case .vcMeetingEndedOverOneHour,
             .vcMeetingEndedLessOneHour,
             .vcMeetingEndedLessOneMin,
             .vcDefaultMeetingEndedOverOneHour,
             .vcDefaultMeetingEndedLessOneHour,
             .vcDefaultMeetingEndedLessOneMin:
            return Resources.LarkFeedPlugin.feed_meeting_end_icon
        case .chatRoomStart:
            return Resources.LarkFeedPlugin.feed_room_icon
        @unknown default:
            return nil
        }
    }

    private func getCardIcon(cardType: RustPB.Basic_V1_CardContent.TypeEnum,
                             isCrypto: Bool) -> UIImage? {
        if cardType == .vchat,
            !isCrypto {
            return Resources.LarkFeedPlugin.feed_meeting_end_icon
        }
        return nil
    }

    private func getVideoChatIcon(videoChatType: RustPB.Basic_V1_VideoChatContent.TypeEnum,
                                  isCrypto: Bool) -> UIImage? {
        if videoChatType == .meetingCard, !isCrypto {
            return Resources.LarkFeedPlugin.feed_meeting_end_icon
        } else if feedPreview.preview.chatData.videoChatType == .chatRoomCard {
            return Resources.LarkFeedPlugin.feed_room_icon
        }
        return nil
    }
}

// MARK: - View
 class ChatFeedCardMsgStatusComponentView: FeedCardBaseComponentView {
    private var msgStatusView: UIView?
    private var isVisible: Bool = false
    private var vm: ChatFeedCardMsgStatusVM?
    // 组件类别
    var type: FeedCardComponentType {
        return .msgStatus
    }
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    var layoutInfo: FeedCardComponentLayoutInfo? {
        return FeedCardComponentLayoutInfo(padding: nil, width: 16.auto(), height: 16.auto())
    }

    func creatView() -> UIView {
        let imageView = UIImageView()
        self.msgStatusView = imageView
        return imageView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UIImageView,
              let vm = vm as? ChatFeedCardMsgStatusVM else { return }
        self.vm = vm
        view.image = vm.icon
        view.isHidden = vm.icon == nil
        self.isVisible = vm.icon != nil
    }

    func subscribedEventTypes() -> [FeedCardEventType] {
        return [.prepareForReuse, .rendered]
    }

    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .prepareForReuse = type, let view = object as? UIView {
            view.isHidden = true
        } else if case .rendered = type,
                  case .rendered(let componentType, let componentValue) = value,
                  componentType == .reaction, let context = componentValue as? [String: Any],
                  let supportHide = vm?.supportHideByEvent as? Bool, supportHide,
                  let hasMore = context[FeedCardReactionComponentView.reactionHasMoreKey] as? Bool {
            msgStatusView?.isHidden = isVisible ? hasMore : true // 在组件可视状态下判断是否要做隐藏操作
        }
    }
}
