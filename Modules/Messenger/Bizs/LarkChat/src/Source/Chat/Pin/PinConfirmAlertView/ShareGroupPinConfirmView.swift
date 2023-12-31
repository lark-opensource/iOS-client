//
//  ShareGroupPinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import Foundation
import UIKit
import LarkModel
import LarkMessageCore

final class ShareGroupPinConfirmView: PinConfirmContainerView {
    private(set) var contentView: ShareGroupView!

    init() {
        self.contentView = ShareGroupView()
        super.init(frame: .zero)
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
        }
        contentView.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let shareGroupVM = contentVM as? ShareGroupPinConfirmViewModel else {
            return
        }
        contentView.delegate = shareGroupVM
        contentView.content = shareGroupVM.content
    }
}

final class ShareGroupPinConfirmViewModel: PinAlertViewModel, ShareGroupViewDelegate {
    var content: ShareGroupChatContent!
    var hasJoinedChat: Bool

    init?(ShareGroupMessage: Message, getSenderName: @escaping (Chatter) -> String, hasJoinedChat: Bool) {
        self.hasJoinedChat = hasJoinedChat
        super.init(message: ShareGroupMessage, getSenderName: getSenderName)

        guard let content = ShareGroupMessage.content as? ShareGroupChatContent else {
            return nil
        }

        self.content = content
    }

    func titleForHadJoinChat() -> String {
        var isTopicGroup = false

        if let chat = self.content.chat {
            isTopicGroup = chat.chatMode == .threadV2
        }
        return isTopicGroup ? BundleI18n.LarkChat.Lark_Groups_JoinedClickToEnter : BundleI18n.LarkChat.Lark_Legacy_ShareGroupEnter
    }

    func hasJoinedChat(_ role: Chat.Role?) -> Bool {
        return hasJoinedChat
    }

    func joinButtonTapped() {
    }

    func headerTapped() {
    }

}
