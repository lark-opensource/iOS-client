//
//  FavoriteMergeForwardPostCardMessageCell.swift
//  LarkChat
//
//  Created by liluobin on 2021/6/15.
//

import UIKit
import Foundation
import SnapKit
import LarkModel
import LarkUIKit
import LarkCore
import EENavigator
import LarkMessengerInterface
import LarkMessageCore
import LarkAccountInterface

final class FavoriteMergeForwardPostCardMessageCell: FavoriteMessageCell {

    override class var identifier: String {
        return FavoriteMergeForwardPostCardMessageViewModel.identifier
    }

    var postCard: MergeForwardCardView?

    override public func setupUI() {
        super.setupUI()
        // mergeForwardView
        guard let vm = self.viewModel as? FavoriteMergeForwardPostCardMessageViewModel, let mergeForwardContent = vm.mergeForwardContent else {
            return
        }
        let cardView: MergeForwardCardView
        if let thread = mergeForwardContent.thread, thread.isReplyInThread {
            cardView = ReplyThreadMergeForwardCardView(contentLabelLines: 3) { [weak self] in
                self?.pushToThreadChat()
            }
        } else {
            cardView = MergeForwardCardView(contentLabelLines: 3) { [weak self] in
                self?.pushToThreadChat()
            }
        }
        cardView.imageViewTap = { [weak self] (visibleThumbnail) in
            self?.showImageDetailWith(visibleThumbnail: visibleThumbnail)
        }
        self.contentWraper.addSubview(cardView)
        cardView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.postCard = cardView
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let mergeForwardVM = self.viewModel as? FavoriteMergeForwardPostCardMessageViewModel, let item = mergeForwardVM.item else {
            return
        }
        self.postCard?.setItem(item)
    }

    private func pushToThreadChat() {
        guard let vm = self.viewModel as? FavoriteMergeForwardPostCardMessageViewModel,
              let window = self.window,
              let content = vm.mergeForwardContent,
              ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: vm.userResolver.userID) else {
            assertionFailure("pushToThreadChat info cannot be nil")
            return
        }
        let chatId = content.fromThreadChat?.id ?? (content.thread?.channel.id ?? "")
        let body = ChatControllerByIdBody(chatId: chatId)
        vm.navigator.push(body: body, from: window)
    }

    private func showImageDetailWith(visibleThumbnail: UIImageView) {
        guard let window = self.window,
              let vm = self.viewModel as? FavoriteMergeForwardPostCardMessageViewModel,
              let image = MergeForwardCardItem.getImagePropertyForMergeForwardMessage(vm.message) else {
            return
        }
        let result = LKDisplayAsset.createAsset(
            postImageProperty: image, isTranslated: false, isAutoLoadOrigin: false, message: vm.message
        )
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
        vm.navigator.present(body: body, from: window)
    }
}
