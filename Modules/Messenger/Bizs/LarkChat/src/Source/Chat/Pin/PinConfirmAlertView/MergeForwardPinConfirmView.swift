//
//  MergeForwardPinConfirmView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/9/13.
//

import Foundation
import UIKit
import LarkCore
import LarkModel
import LarkContainer

// MARK: - MergeForwardPinConfirmView
final class MergeForwardPinConfirmView: PinConfirmContainerView {
    var mergeForwardView: MergeForwardView

    override init(frame: CGRect) {
        self.mergeForwardView = MergeForwardView(titleLines: 1, contentLabelLines: 2, tapHandler: nil)

        super.init(frame: frame)

        self.addSubview(mergeForwardView)
        mergeForwardView.snp.makeConstraints { (make) in
            make.top.left.equalTo(BubbleLayout.commonInset.left)
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? MergeForwardPinConfirmViewModel else {
            return
        }

        let maxWidth = LarkChatUtils.pinAlertConfirmMaxWidth - 2 * BubbleLayout.commonInset.left
        self.mergeForwardView.set(
            contentMaxWidth: maxWidth,
            title: contentVM.title,
            attributeText: contentVM.contentText
        )
    }
}

// MARK: - MergeForwardPinConfirmViewModel
final class MergeForwardPinConfirmViewModel: PinAlertViewModel {
    var title: String = ""
    var contentText: NSAttributedString = NSAttributedString(string: "")

    init?(userResolver: UserResolver, mergeMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        super.init(message: mergeMessage, getSenderName: getSenderName)

        guard let content = mergeMessage.content as? MergeForwardContent else {
            return nil
        }

        self.title = content.title
        self.contentText = content.getContentText(userResolver: userResolver)
    }
}
