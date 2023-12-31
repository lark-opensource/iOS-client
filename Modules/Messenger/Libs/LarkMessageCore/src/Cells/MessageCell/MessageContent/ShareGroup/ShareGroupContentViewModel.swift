//
//  ShareGroupContentViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/11.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkMessageBase
import EENavigator
import LarkSDKInterface
import LarkSetting
import LarkMessengerInterface
import ServerPB
import LarkCore
import RustPB

public final class ShareGroupContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ShareGroupContentContext>: MessageSubViewModel<M, D, C>, ShareGroupViewDelegate {

    private let shareGroupContentConfig: ShareGroupContentConfig

    public init(metaModel: M,
                metaModelDependency: D,
                context: C,
                binder: ComponentBinder<C>,
                shareGroupContentConfig: ShareGroupContentConfig = ShareGroupContentConfig()) {
        self.shareGroupContentConfig = shareGroupContentConfig
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    override public var identifier: String {
        return "share-group"
    }

    public var threadMiniIconEnableFg: Bool {
        return self.context.threadMiniIconEnableFg
    }

    public var content: ShareGroupChatContent {
        return (self.message.content as? ShareGroupChatContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    public func hasJoinedChat(_ role: Chat.Role?) -> Bool {
        return role == .member
    }

    // 分享群的添加状态
    private lazy var joinStatus: JoinGroupApplyBody.Status = {
        getEnduranceJoinStatusFromContent(content)
    }()

    public override func update(metaModel: M, metaModelDependency: D?) {
        // 目前只处理假消息上屏后再收到push后的卡片状态更新
        if let shareGroupChatContent = metaModel.message.content as? ShareGroupChatContent,
           isEnduranceJoinStatus(joinStatus) {
            self.joinStatus = getEnduranceJoinStatusFromContent(shareGroupChatContent)
        }
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    // 这里只根据content返回持久化的状态
    private func getEnduranceJoinStatusFromContent(_ content: ShareGroupChatContent) -> JoinGroupApplyBody.Status {
        if self.hasJoinedChat(content.chat?.role) {
            return .hadJoined
        } else if content.joinToken.isEmpty || (content.expireTime > 0 && content.expireTime < Date().timeIntervalSince1970) {
            return .expired
        } else if content.chat?.isDissolved ?? false {
            return .groupDisband
        }
        return .unTap
    }

    // 有一些状态目前没法做持久化（没有实体存储，需要依赖接口返回）， 因此抽象出一个方法来判断是否是持久化的状态
    private func isEnduranceJoinStatus(_ status: JoinGroupApplyBody.Status) -> Bool {
        return status == .hadJoined || status == .expired || status == .groupDisband || status == .unTap
    }

    public var joinStatusText: String {
        switch joinStatus {
        case .unTap, .cancel:
            return BundleI18n.LarkMessageCore.Lark_Groups_GroupCard
        default:
            return ShareGroupJoinStatusManager.transfromToDisplayString(status: joinStatus,
                                                                        isTopicGroup: self.content.chat?.chatMode == .threadV2)
        }
    }

    public var joinButtonText: String {
        guard displayJoinButton else { return "" }
        switch joinStatus {
        case .unTap, .waitAccept, .cancel:
            return BundleI18n.LarkMessageCore.Lark_Legacy_JoinGroupChat
        case .hadJoined:
            return BundleI18n.LarkMessageCore.Lark_Legacy_Open
        default:
            return BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupExpired
        }
    }

    var joinButtonTextColor: UIColor {
        switch joinStatus {
        case .unTap, .waitAccept, .cancel:
            return UIColor.ud.primaryContentDefault
        default:
            return UIColor.ud.textTitle
        }
    }

    var joinButtonBorderColor: UIColor {
        if !joinButtonEnable { return UIColor.ud.lineBorderComponent }
        switch joinStatus {
        case .unTap, .waitAccept, .cancel:
            return UIColor.ud.primaryContentDefault
        default:
            return UIColor.ud.lineBorderComponent
        }
    }

    public var displayJoinButton: Bool {
        return ShareGroupJoinStatusManager.isTapAbleStatus(joinStatus) || joinStatus == .waitAccept
    }

    public var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(joinStatus)
    }

    public func titleForHadJoinChat() -> String {
        var isTopicGroup = false
        if let chat = self.content.chat {
            isTopicGroup = chat.chatMode == .threadV2
        }
        return isTopicGroup ? BundleI18n.LarkMessageCore.Lark_Groups_JoinedClickToEnter : BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupEnter
    }

    public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    private let disposebag = DisposeBag()

    public func joinButtonTapped() {
        guard joinButtonEnable, let chat = content.chat else { return }

        if self.context.scene == .newChat || self.context.scene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.ShareGroupChat(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.context.scene == .threadDetail || self.context.scene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.ShareGroupChat(self.metaModel.getChat(), self.message)
        }
        joinedChat()
    }

    private func joinedChat() {
        guard joinButtonEnable, let chat = content.chat else { return }
        if self.hasJoinedChat(chat.role) {
            showChatController()
            return
        }

        showJoinGroupApply()
    }

    public func headerTapped() {
        if let chat = content.chat {
            IMTracker.Chat.Main.Click.groupCardTitleShare(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        }
        guard let chat = content.chat else { return }
        if self.context.scene == .newChat || self.context.scene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.ShareGroupChat(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.context.scene == .threadDetail || self.context.scene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.ShareGroupChat(self.metaModel.getChat(), self.message)
        }
        if self.hasJoinedChat(chat.role) {
            showChatController()
            return
        }
        showPreviewChat()
    }

    public override var contentConfig: ContentConfig? {
        var contentConfig = ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        contentConfig.isCard = true
        return contentConfig
    }

    public var hasPaddingBottom: Bool {
        if let hasPaddingBottom = shareGroupContentConfig.hasPaddingBottom {
            return hasPaddingBottom
        }
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), !message.reactions.isEmpty, !self.message.showInThreadModeStyle { return false }
        return true
    }

    private func showPreviewChat() {
        let body = PreviewChatBody(messageId: message.id,
                                   content: content,
                                   joinStatus: self.joinStatus) { [weak self] status in
            guard let `self` = self else { return }
            if self.joinStatus != status {
                self.joinStatus = status
                var content = self.content
                content.expired = status == .expired
                content.chat?.role = (status == .hadJoined) ? .member : .visitor
                self.message.content = content
                self.binder.update(with: self)
                self.update(component: self.binder.component, animation: .none)
            }
        }
        context.navigator(type: .push, body: body, params: nil)
    }

    private func showChatController() {
        let body = ChatControllerByIdBody(chatId: content.shareChatID, fromWhere: .card)
        context.navigator(type: .push, body: body, params: nil)
    }

    private func showJoinGroupApply() {
        let body = JoinGroupApplyBody(
            chatId: content.shareChatID,
            way: .viaShare(joinToken: content.joinToken,
                           messageId: message.id,
                           isTimeExpired: Date().timeIntervalSince1970 > content.expireTime)
        ) { [weak self] status in
            guard let self = self else { return }
            let isToastRemind = ShareGroupJoinStatusManager.isShowToastStatus(status)
            let mindToast = isToastRemind ? ShareGroupJoinStatusManager.transfromToTrackString(status: status) : nil
            if let chat = self.content.chat {
                IMTracker.Chat.Main.Click.groupCardButtonShare(chat,
                                                               self.message,
                                                               self.context.trackParams[PageContext.TrackKey.sceneKey] as? String,
                                                               isToastRemind: isToastRemind,
                                                               toastRemind: mindToast)
            }
            if self.joinStatus != status {
                self.joinStatus = status
                // update message content & refresh UI
                self.context.reloadRows(by: [self.message.id]) { [weak self]  (message) -> Message? in
                    guard let self = self else { return message }
                    var content = self.content
                    content.chat?.role = (status == .hadJoined) ? .member : .visitor
                    content.expired = status == .expired
                    message.content = content
                    return message
                }
            }
        }
        context.navigator(type: .open, body: body, params: nil)
    }
}

public struct ShareGroupJoinStatusManager {
    // 是否是可点击状态
    public static func isTapAbleStatus(_ status: JoinGroupApplyBody.Status) -> Bool {
        status == .unTap || status == .hadJoined || status == .cancel
    }

    // 是否是不可点击状态
    public static func isUnTapAbleStatus(_ status: JoinGroupApplyBody.Status) -> Bool {
        !isTapAbleStatus(status)
    }

    // 是否是展示toast的状态
    public static func isShowToastStatus(_ status: JoinGroupApplyBody.Status) -> Bool {
        switch status {
        case .ban, .groupDisband, .noPermission, .sharerQuit, .numberLimit, .contactAdmin:
            return true
        default:
            return false
        }
    }

    public static func transfromToTrackString(status: JoinGroupApplyBody.Status) -> String {
        switch status {
        case .contactAdmin:
            return "external_user_cannot_operate"
        case .noPermission:
            return "internal_user_cannot_operate"
        case .sharerQuit:
            return "sharing_group_user_exit"
        case .numberLimit:
            return "group_member_full"
        case .ban:
            return "sharing_method_stop"
        case .groupDisband:
            return "group_disband"
        default:
            return ""
        }
    }

    public static func transfromToDisplayString(status: JoinGroupApplyBody.Status,
                                                isTopicGroup: Bool = false) -> String {
        switch status {
        case .hadJoined:
            // 在群内提示进入该群
            return isTopicGroup ? BundleI18n.LarkMessageCore.Lark_Groups_JoinedClickToEnter : BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupEnter
        case .expired:
            // 该分享已经过期
            return BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupExpired
        case .unTap, .cancel:
            // 加入该群
            return BundleI18n.LarkMessageCore.Lark_Legacy_JoinGroupChat
        case .waitAccept:
            // 等待验证
            return BundleI18n.LarkMessageCore.Lark_Group_PendingApprovalButton
        case .noPermission:
            // 无对外沟通权限
            return BundleI18n.LarkMessageCore.Lark_Group_UnableJoinExternalGroup
        case .sharerQuit:
            // 分享者退群
            return BundleI18n.LarkMessageCore.Lark_Group_InviterLeftButton
        case .numberLimit:
            // 群人数已满
            return BundleI18n.LarkMessageCore.Lark_Legacy_GroupMemberOutOfRange
        case .ban:
            // 分享被停用
            return BundleI18n.LarkMessageCore.Lark_Group_InvitationDisabledButton
        case .groupDisband:
            // 群已经解散
            return BundleI18n.LarkMessageCore.Lark_Group_DisbandedButton
        case .contactAdmin:
            // 企业内部群，暂不支持外部成员加入
            return BundleI18n.LarkMessageCore.Lark_Group_ContactAdminButton
        case .nonCertifiedTenantRefuse:
            // 非认证租户
            return BundleI18n.LarkMessageCore.Lark_Groups_CantJoinGroup
        // 默认显示分享已失效
        default:
            return BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupExpired
        }
    }
}
