//
//  FeedMainViewController+FeedModuleVCDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import UIKit
import Foundation
import RustPB
import LarkOpenFeed

extension FeedMainViewController: FeedModuleVCDelegate {
    // TODO: 需要优化
    func isHasFlagGroup() -> Bool {
        return filterTabViewModel.dataStore.usedFiltersDS.contains(where: { $0.type == .flag })
    }

    func scrollTop(animated: Bool) {
        setContentOffset(.zero, animated: animated)
    }

    func backFirstList() {
        changeTabWithFilterSelectItem(mainViewModel.firstTab)
    }

    func pullupMainScrollView() {
        let adjustedHeight = filterTabViewModel.isSupportCeiling ? 0 : filterTabViewModel.viewHeight
        let value = headerView.bounds.size.height + adjustedHeight
        if self.mainScrollView.contentOffset.y < value {
            setContentOffset(CGPoint(x: 0, y: value), animated: true)
        }
    }

    func getFirstTab() -> Feed_V1_FeedFilter.TypeEnum {
        return mainViewModel.firstTab
    }
}
