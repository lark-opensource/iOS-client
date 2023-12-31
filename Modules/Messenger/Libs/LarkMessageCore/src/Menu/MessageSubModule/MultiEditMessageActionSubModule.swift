//
//  MultiEdit.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/16.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import LKCommonsTracker
import LarkCore
import LarkSDKInterface
import UniverseDesignToast
import LarkOpenChat
import LarkAccountInterface
import LarkFeatureGating

public class MultiEditMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .multiEdit
    }
    @ScopedInjectedLazy fileprivate var tenantUniversalSettingService: TenantUniversalSettingService?

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return context.userResolver.fg.staticFeatureGatingValue(with: "messenger.message.edit_message")
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if model.message.isSinglePreview {
            return false
        }
        switch model.message.type {
        case .text, .post: break
        @unknown default: return false
        }

        var isGroupAnnouncement = false
        if let postContent = model.message.content as? PostContent {
            isGroupAnnouncement = postContent.isGroupAnnouncement
        }
        // 判断是否是自己发送的消息
        let anonymousId = model.chat.anonymousId
        let fromMe = self.context.userID == model.message.fromId ||
        (!anonymousId.isEmpty && anonymousId == model.message.fromId)
        guard fromMe,
              model.chat.isAllowPost,
              tenantUniversalSettingService?.getIfMessageCanMultiEdit(createTime: model.message.createTime) ?? false,
              !isGroupAnnouncement else {
            return false
        }
        return true
    }

    private func handle(message: Message, chat: Chat) {
        guard let pageAPI = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).pageAPI else { return }
        guard tenantUniversalSettingService?.getIfMessageCanMultiEdit(createTime: message.createTime) ?? false else {
            UDToast.showFailure(with: self.getOvertimeToastContent(tenantUniversalSettingService?.getEditEffectiveTime() ?? 0), on: pageAPI.view)
            return
        }
        pageAPI.multiEdit(message)
    }

    private func getOvertimeToastContent(_ effectiveTime: Int64) -> String {
        var num = effectiveTime //秒
        num /= 60               //分钟
        if num < 60 {           //60分钟要显示为1小时
            return BundleI18n.LarkMessageCore.Lark_IM_EditMessage_AdminAllowEditWithinNumMin_Toast(num)
        }
        num /= 60               //小时
        if num <= 24 {          //24小时要显示为24小时，而非1天
            return BundleI18n.LarkMessageCore.Lark_IM_EditMessage_AdminAllowEditWithinNumHr_Toast(num)
        }
        num /= 24               //天
        return BundleI18n.LarkMessageCore.Lark_IM_EditMessage_AdminAllowEditWithinNumDays_Toast(num)
    }

    fileprivate func getItemTitleText(by message: Message) -> String {
        BundleI18n.LarkMessageCore.Lark_IM_EditMessage_Button
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: getItemTitleText(by: model.message),
                                 icon: BundleResources.Menu.menu_multiEdit,
                                 showDot: !model.message.editDraftId.isEmpty,
                                 trackExtraParams: ["click": "edit_msg", "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}

public final class MultiEditMessageActionSubModuleInThread: MultiEditMessageActionSubModule {
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        var isGroupAnnouncement = false
        if let postContent = model.message.content as? PostContent {
            isGroupAnnouncement = postContent.isGroupAnnouncement
        }
        let anonymousId = model.chat.anonymousId
        let isFromMe = self.context.userID == model.message.fromId ||
        (!anonymousId.isEmpty && anonymousId == model.message.fromId)
        let allowEdit: Bool
        if model.chat.chatMode == .threadV2,
           !model.message.rootId.isEmpty { //rootId不为空表示是回帖
            // 话题群即便被禁言，也可以回帖子，因此也可以编辑回帖
            allowEdit = true
        } else {
            allowEdit = model.chat.isAllowPost
        }
        guard isFromMe,
              allowEdit,
              !model.message.isNoTraceDeleted && model.message.rootMessage?.isNoTraceDeleted != true,
              model.isOpen,
              !isGroupAnnouncement,
              tenantUniversalSettingService?.getIfMessageCanMultiEdit(createTime: model.message.createTime) ?? false else {
            return false
        }

        switch model.message.type {
        case .text, .post:
            return true
        @unknown default:
            return false
        }
    }
    override func getItemTitleText(by message: Message) -> String {
        if !message.rootId.isEmpty || message.threadMessageType == .threadReplyMessage {
            return BundleI18n.LarkMessageCore.Lark_IM_EditTopicReply_Button
        } else {
            return BundleI18n.LarkMessageCore.Lark_IM_EditTopic_Button
        }
    }
}
