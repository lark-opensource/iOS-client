//
//  FlagMergeForwardPostCardMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel
import LarkUIKit
import LarkCore
import LKCommonsLogging
import LarkMessageCore

private final class FlagMergeForwardPostCardMessageViewModelLogger {
    static let logger = Logger.log(FlagMergeForwardPostCardMessageViewModel.self, category: "flagMergeForward")
}

final class FlagMergeForwardPostCardMessageViewModel: FlagMessageCellViewModel {
    private static let logger = Logger.log(FlagMergeForwardPostCardMessageViewModel.self, category: "FlagMergeForwardPostCardMessageViewModel")

    override public class var identifier: String {
        return String(describing: FlagMergeForwardPostCardMessageViewModel.self)
    }

    override public var identifier: String {
        return FlagMergeForwardPostCardMessageViewModel.identifier
    }

    public var mergeForwardContent: MergeForwardContent? {
        return self.message.content as? MergeForwardContent
    }

    public var item: MergeForwardCardItem?

    public override func setupMessage() {
        super.setupMessage()

        guard let content = self.mergeForwardContent else {
            return
        }
        configData(content)
    }

    func configData(_ content: MergeForwardContent) {
        var title = ""
        var fromChatterName = ""
        if let firstMessage = content.messages.first {
            fromChatterName = content.chatters[firstMessage.fromId]?.name ?? ""
        }
        let imagekey: String = MergeForwardCardItem.getImageKeyForMergeForwardMessage(message) ?? ""
        var fromAvatarKey = ""
        var fromAvatarEntityId = ""
        var fromTitle = BundleI18n.LarkFlag.Lark_Group_FromTopicGroup
        var isGroupMember = false
        let currentChatterId = self.userResolver.userID
        if content.thread?.isReplyInThread == true {
            if ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: currentChatterId) {
                fromAvatarKey = ReplyInThreadMergeForwardDataManager.fromAvatarFor(content: content, currentChatterId: currentChatterId)
                fromAvatarEntityId = ReplyInThreadMergeForwardDataManager.fromAvatarEntityId(content: content, currentChatterId: currentChatterId)
                fromTitle = ReplyInThreadMergeForwardDataManager.fromTitleFor(content: content, currentChatterId: currentChatterId)
                isGroupMember = true
            }
            title = BundleI18n.LarkFlag.Lark_IM_Thread_UsernameThreadCard_Title(fromChatterName)
        } else {
            if content.fromThreadChat?.role == .member {
                fromAvatarKey = content.fromThreadChat?.avatarKey ?? ""
                fromAvatarEntityId = content.fromThreadChat?.id ?? ""
                fromTitle = content.fromThreadChat?.name ?? ""
            }
            isGroupMember = content.fromThreadChat?.role == .member
            title = BundleI18n.LarkFlag.Lark_Group_NamesTopic(fromChatterName)
        }
        FlagMergeForwardPostCardMessageViewModelLogger.logger.info("card info -- subtitle count \(content.thread?.subtitle.count ?? 0), chat.role ---\(content.fromThreadChat?.role ?? .ignore)")
        let cardItem = MergeForwardCardItem(title: title,
                                            content: content.thread?.subtitle ?? "",
                                            imageKey: imagekey,
                                            fromTitle: fromTitle,
                                            fromAvatarKey: fromAvatarKey,
                                            fromAvatarEntityId: fromAvatarEntityId,
                                            isGroupMember: isGroupMember)
        self.item = cardItem
    }

    override public var needAuthority: Bool {
        return false
    }
}
