//
//  FlagMergeForwardPostCardMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import SnapKit
import LarkModel
import LarkUIKit
import LarkCore
import EENavigator
import LarkMessageCore
import LarkMessengerInterface

final class FlagMergeForwardPostCardMessageCell: FlagMessageCell {

    override class var identifier: String {
        return FlagMergeForwardPostCardMessageViewModel.identifier
    }

    var postCard: MergeForwardCardView?

    override public func setupUI() {
        super.setupUI()
        // mergeForwardView
        let cardView = MergeForwardCardView(contentLabelLines: 3) { [weak self] in
            self?.pushToThreadChat()
        }
        cardView.imageViewTap = { [weak self] (visibleThumbnail) in
            self?.showImageDetailWith(visibleThumbnail: visibleThumbnail)
        }
        self.contentWraper.addSubview(cardView)
        cardView.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview()
        }
        self.postCard = cardView
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let mergeForwardVM = self.viewModel as? FlagMergeForwardPostCardMessageViewModel, let item = mergeForwardVM.item else {
            return
        }
        self.postCard?.setItem(item)
    }

    private func pushToThreadChat() {
        guard let vm = self.viewModel as? FlagMergeForwardPostCardMessageViewModel,
              let window = self.window,
              let content = vm.mergeForwardContent,
              ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: vm.userResolver.userID) else {
            assertionFailure("pushToThreadChat info cannot be nil")
            return
        }
        let chatId = content.fromThreadChat?.id ?? (content.thread?.channel.id ?? "")
        let body = ChatControllerByIdBody(chatId: chatId)
        vm.userResolver.navigator.push(body: body, from: window)
    }

    private func showImageDetailWith(visibleThumbnail: UIImageView) {
        guard let window = self.window,
              let vm = self.viewModel as? FlagMergeForwardPostCardMessageViewModel,
              let image = MergeForwardCardItem.getImagePropertyForMergeForwardMessage(vm.message) else {
            return
        }
        let result = LKDisplayAsset.createAsset(postImageProperty: image, isTranslated: false, isAutoLoadOrigin: false, message: vm.message)
        result.visibleThumbnail = visibleThumbnail
        let body = PreviewImagesBody(assets: [result.transform()],
                                     pageIndex: 0,
                                     scene: .normal(assetPositionMap: [:], chatId: nil),
                                     trackInfo: PreviewImageTrackInfo(scene: .Forward),
                                     shouldDetectFile: vm.chat?.shouldDetectFile ?? true,
                                     canShareImage: false,
                                     canEditImage: true,
                                     canTranslate: false,
                                     translateEntityContext: (nil, .other))
        vm.userResolver.navigator.present(body: body, from: window)
    }
}
