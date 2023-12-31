//
//  FeedMainViewController+SplitViewControllerDelegate.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/14.
//

import Foundation
import LarkSplitViewController

/// iPadFeed三栏容器SplitVC代理方法
extension FeedMainViewController: SplitViewControllerDelegate {
    func splitViewControllerDidCollapse(_ svc: SplitViewController) {
        styleService.updateStyle(svc.isCollapsed)

    }

    func splitViewControllerDidExpand(_ svc: SplitViewController) {
        styleService.updateStyle(svc.isCollapsed)
    }

    func splitViewController(_ svc: SplitViewController, didChangeTo splitMode: SplitViewController.SplitMode) {
        if splitMode == .oneOverSecondary || splitMode == .oneBesideSecondary {
            styleService.updatePadUnfoldStatus(false)
        } else if splitMode == .twoOverSecondary || splitMode == .twoBesideSecondary || splitMode == .twoDisplaceSecondary {
            styleService.updatePadUnfoldStatus(true)
        } else {
            styleService.updatePadUnfoldStatus(nil)
        }
    }
}
