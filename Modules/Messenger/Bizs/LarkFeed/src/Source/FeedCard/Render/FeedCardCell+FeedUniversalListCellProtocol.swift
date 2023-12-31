//
//  FeedCardCell+FeedUniversalListCellProtocol.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/20.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkSceneManager
import LarkModel
import LarkUIKit
import UniverseDesignTheme

extension FeedCardCell: FeedUniversalListCellProtocol {
    var viewModel: FeedCardCellViewModel? {
        return cellViewModel
    }

    var feedPreview: FeedPreview? {
        return cellViewModel?.feedPreview
    }

    func didSelectCell(from: UIViewController, trace: FeedListTrace, filterType: Feed_V1_FeedFilter.TypeEnum) {
        guard let cellViewModel = self.cellViewModel else { return }
        if let feedCard = self.viewModel, feedCard.feedPreview.basicMeta.feedPreviewPBType == .appFeed {
            FeedTracker.FeedCard.Click.AppFeed(feedPreview: feedCard.feedPreview, basicData: feedCard.basicData, bizData: feedCard.bizData, iPadStatus: nil)
        }
        if let context = module?.feedCardContext {
            FeedActionFactoryManager.performJumpAction(
                feedPreview: cellViewModel.feedPreview,
                context: context,
                from: from,
                basicData: cellViewModel.basicData,
                bizData: cellViewModel.bizData,
                extraData: cellViewModel.extraData
            )
        }

        let preview = cellViewModel.feedPreview
        FeedPerfTrack.trackFeedCellClick(preview)
        FeedTeaTrack.trackFilterChatClick(preview: preview, from: from)
        var logInfo = "feedlog/feedcard/action/tap. filterType: \(filterType), \(trace.description), cellAddress: \(ObjectIdentifier(self))"
        logInfo.append(", cellVMAddress: \(ObjectIdentifier(cellViewModel)), preview: \(preview.description)")
        FeedContext.log.info(logInfo)
    }
}
