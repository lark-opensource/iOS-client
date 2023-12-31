//
//  MergeForwardCardPinConfirmView.swift
//  LarkChat
//
//  Created by liluobin on 2021/6/18.
//

import Foundation
import UIKit
import LarkCore
import LarkModel
import LarkContainer
import LarkMessengerInterface
import LarkMessageCore
import LarkAccountInterface

final class ReplyInThreadMergeForwardCardPinConfirmView: MergeForwardCardPinConfirmView {
    override func setupCardView() {
        let cardView = ReplyThreadMergeForwardCardView(tapHandler: nil)
        self.addSubview(cardView)
        cardView.snp.makeConstraints { (make) in
            make.top.left.equalTo(BubbleLayout.commonInset.left)
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
        }
        self.cardView = cardView
    }
}

class MergeForwardCardPinConfirmView: PinConfirmContainerView {
    var cardView: MergeForwardCardView?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCardView()
    }
    func setupCardView() {
        let cardView = MergeForwardCardView(tapHandler: nil)
        self.addSubview(cardView)
        cardView.snp.makeConstraints { (make) in
            make.top.left.equalTo(BubbleLayout.commonInset.left)
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
        }
        self.cardView = cardView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? MergeForwardCardPinConfirmViewModel,
              let item = contentVM.item else {
            return
        }
        self.cardView?.setItem(item)
    }

}
// MARK: - MergeForwardPinConfirmViewModel
final class MergeForwardCardPinConfirmViewModel: PinAlertViewModel, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    var item: MergeForwardCardItem?
    init?(userResolver: UserResolver, mergeMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        self.userResolver = userResolver
        super.init(message: mergeMessage, getSenderName: getSenderName)

        guard let content = mergeMessage.content as? MergeForwardContent else {
            return nil
        }
        configData(content)
    }

    func configData(_ content: MergeForwardContent) {
        var title = ""
        var fromAvatarKey = ""
        var fromAvatarEntityId = ""
        var isGroupMember = false
        var fromTitle = BundleI18n.LarkChat.Lark_Group_FromTopicGroup
        let imageKey = MergeForwardCardItem.getImageKeyForMergeForwardMessage(message) ?? ""
        var fromChatterName = ""
        if let fromId = content.messages.first?.fromId, let name = content.chatters[fromId]?.name {
            fromChatterName = name
        }
        let currentChatterId = self.userResolver.userID
        if content.thread?.isReplyInThread == true {
            if ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: currentChatterId) {
                fromAvatarKey = ReplyInThreadMergeForwardDataManager.fromAvatarFor(content: content, currentChatterId: currentChatterId)
                fromAvatarEntityId = ReplyInThreadMergeForwardDataManager.fromAvatarEntityId(content: content, currentChatterId: currentChatterId)
                fromTitle = ReplyInThreadMergeForwardDataManager.fromTitleFor(content: content, currentChatterId: currentChatterId)
                isGroupMember = true
            }
            title = BundleI18n.LarkChat.Lark_IM_Thread_UsernameThreadCard_Title(fromChatterName)
        } else {
            if content.fromThreadChat?.role == .member {
                fromAvatarKey = content.fromThreadChat?.avatarKey ?? ""
                fromAvatarEntityId = content.fromThreadChat?.id ?? ""
                fromTitle = content.fromThreadChat?.name ?? ""
            }
            isGroupMember = content.fromThreadChat?.role == .member
            title = BundleI18n.LarkChat.Lark_Group_NamesTopic(fromChatterName)
        }

        var previewPermission: (Bool, ValidateResult?) = (true, nil)
        if let firstMsg = content.messages.first, let chatSecurityControlService {
            previewPermission = chatSecurityControlService.checkPermissionPreview(anonymousId: "", message: firstMsg)
        }
        item = MergeForwardCardItem(title: title,
                                    content: content.thread?.subtitle ?? "",
                                    imageKey: imageKey,
                                    fromTitle: fromTitle,
                                    fromAvatarKey: fromAvatarKey,
                                    fromAvatarEntityId: fromAvatarEntityId,
                                    isGroupMember: isGroupMember,
                                    previewPermission: previewPermission)

    }
}
