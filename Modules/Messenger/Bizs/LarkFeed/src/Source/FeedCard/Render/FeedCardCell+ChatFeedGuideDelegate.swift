//
//  FeedCardCell+ChatFeedGuideDelegate.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/20.
//

import UIKit
import Foundation
import RustPB
import LarkModel
import LarkOpenFeed
import LarkBizAvatar

/// Feed引导(At/At All/Badge)
extension FeedCardCell: ChatFeedGuideDelegate {
    var isChat: Bool {
        guard let module = self.module, module.type == .chat else {
            return false
        }
        return true
    }

    var hasAtInfo: Bool {
        return viewModel?.feedPreview.uiMeta.mention.hasAtInfo ?? false
    }

    var atInfo: FeedPreviewAt {
        return viewModel?.feedPreview.uiMeta.mention.atInfo ?? .default()
    }

    var isRemind: Bool {
        return viewModel?.feedPreview.basicMeta.isRemind ?? false
    }

    var unreadCount: Int {
        return viewModel?.feedPreview.basicMeta.unreadCount ?? 0
    }

    var atView: UIView? {
        return subViewsMap[.mention]
    }

    var badgeView: UIView? {
        guard let avatarView = subViewsMap[.avatar] as? LarkMedalAvatar else {
            return nil
        }
        return avatarView.topBadge
    }

    func routerToNextPage(from: UIViewController, context: FeedContextService?) {
        guard let vm = viewModel, let context = module?.feedCardContext else { return }
        FeedActionFactoryManager.performJumpAction(
            feedPreview: vm.feedPreview,
            context: context,
            from: from,
            basicData: vm.basicData,
            bizData: vm.bizData,
            extraData: vm.extraData
        )
    }
}
