//
//  FlagMergeForwardMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import SnapKit
import LarkModel
import LarkUIKit
import LarkCore
import LarkContainer
import EENavigator
import LarkMessengerInterface

final class FlagMergeForwardMessageCell: FlagMessageCell {

    override class var identifier: String {
        return FlagMergeForwardMessageViewModel.identifier
    }

    var mergeForwardView: MergeForwardView = .init(tapHandler: nil)

    override public var bubbleContentMaxWidth: CGFloat {
        return UIScreen.main.bounds.width - 2 * Cons.contentInset - Cons.avatarRightMargin - Cons.avatarSize - Cons.contentRightMargin
    }

    override public func setupUI() {
        super.setupUI()

        // mergeForwardView
        let mergeForwardView = MergeForwardView(contentLabelLines: 4, tapHandler: nil)
        mergeForwardView.isUserInteractionEnabled = true
        mergeForwardView.lu.addTapGestureRecognizer(action: #selector(mergeForwardViewDidTapped), target: self)
        self.contentWraper.addSubview(mergeForwardView)
        mergeForwardView.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        self.mergeForwardView = mergeForwardView
    }

    override public func updateCellContent() {
        super.updateCellContent()

        guard let mergeForwardVM = self.viewModel as? FlagMergeForwardMessageViewModel else {
            return
        }

        self.mergeForwardView.set(
            contentMaxWidth: self.bubbleContentMaxWidth,
            title: mergeForwardVM.title,
            attributeText: mergeForwardVM.contentText
        )
    }

    @objc
    fileprivate func mergeForwardViewDidTapped() {
        guard let mergeForwardVM = self.viewModel as? FlagMergeForwardMessageViewModel, mergeForwardVM.message.type == .mergeForward, let chat = mergeForwardVM.chat else {
            assertionFailure("mergeForwardVM cannot be nil")
            return
        }
        guard let window = self.window else {
            assertionFailure()
            return
        }
        // 标记这个cell被选中了
        self.markForSelect()
        let body: MergeForwardDetailBody
        if chat.id == mergeForwardVM.message.channel.id {
            body = MergeForwardDetailBody(message: mergeForwardVM.message, chat: chat, downloadFileScene: .favorite)
        } else {
            body = MergeForwardDetailBody(message: mergeForwardVM.message, chatId: mergeForwardVM.message.channel.id, downloadFileScene: .favorite)
        }
        mergeForwardVM.userResolver.navigator.push(body: body, from: window)
    }
}
