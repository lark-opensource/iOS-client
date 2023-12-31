//
//  SplitViewController+DisplayMode.swift
//  SplitViewControllerDemo
//
//  Created by Yaoguoguo on 2022/8/15.
//

import Foundation

extension SplitViewController {

    @objc
    public enum SplitMode: Int {

        // Only the secondary view controller is shown onscreen.
        case secondaryOnly = 0

        // One sidebar appears side-by-side with the secondary view controller.
        case oneBesideSecondary = 1

        // One sidebar is layered on top of the secondary view controller, leaving the secondary view controller partially visible.
        case oneOverSecondary = 2

        // Two sidebars appear side-by-side with the secondary view controller.
        case twoBesideSecondary = 3

        // Two sidebars are layered on top of the secondary view controller, leaving the secondary view controller partially visible.
        case twoOverSecondary = 4

        // Two sidebars displace the secondary view controller instead of overlapping it, moving it partially offscreen.
        case twoDisplaceSecondary = 5

        // Only the side view is shown onscreen.
        case sideOnly = 6
    }

    public func updateSplitMode(_ mode: SplitViewController.SplitMode, animated: Bool) {
        self.updateBehaviorAndSplitMode(behavior: self.splitBehavior,
                                        splitMode: mode,
                                        animated: animated)
    }
}
