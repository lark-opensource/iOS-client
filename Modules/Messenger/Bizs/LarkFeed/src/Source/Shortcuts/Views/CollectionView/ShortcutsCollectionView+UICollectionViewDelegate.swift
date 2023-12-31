//
//  ShortcutsCollectionView+UICollectionViewDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15.
//

import UIKit
import Foundation
import EENavigator
import LarkUIKit
import LarkMessengerInterface
import LarkSDKInterface
import LarkOpenFeed
import RustPB

extension ShortcutsCollectionView: UICollectionViewDelegate {
    // 按任意collection cell，即toggle置顶区域的状态
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var logInfo = "feedlog/shortcut/tap. row: \(indexPath.row), "
        defer {
            FeedContext.log.info(logInfo)
        }
        guard let vc = self.parentVC else {
            logInfo.append("parentVC is nil, ")
            return
        }
        guard indexPath.row < viewModel.dataSource.count else {
            logInfo.append("totalCount: \(viewModel.dataSource.count), ")
            return
        }
        let shortcut = viewModel.dataSource[indexPath.row]
        logInfo.append("info: \(shortcut.description), ")
        guard !viewModel.shouldSkip(feedId: shortcut.id, traitCollection: horizontalSizeClass) else {
            logInfo.append("skip, ")
            return
        }

        if let context = try? viewModel.userResolver.resolve(assert: FeedCardContext.self) {
            FeedActionFactoryManager.performJumpAction(
                feedPreview: shortcut.preview,
                context: context,
                from: vc,
                basicData: nil,
                bizData: nil,
                extraData: [:])
        }

        FeedTeaTrack.trackEnterFromShortCut(chatID: shortcut.id,
                                            type: shortcut.charTotalType,
                                            subType: shortcut.chatSubType)
    }
}
