//
//  FullScreenItemManager.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/10.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkSplitViewController

public final class NavigationBarSubModuleTool {
    static func enterFullScreenFor(vc: UIViewController) {
        vc.larkSplitViewController?.updateSplitMode(.secondaryOnly, animated: true)

        LarkSplitViewController.Tracker.trackFullScreenItemClick(
            scene: vc.fullScreenSceneBlock?(), isFold: true
        )
    }

    static func leaveFullScreenItemFor(vc: UIViewController) {
        if let split = vc.larkSplitViewController {
            split.updateSplitMode(split.beforeSecondaryOnlySplitMode, animated: true)
        }
        LarkSplitViewController.Tracker.trackFullScreenItemClick(
            scene: vc.fullScreenSceneBlock?(), isFold: false
        )
    }

    static func updateFullScreenItemFor(vc: UIViewController, finish: ((Bool, Bool?) -> Void)?) {
        if let split = vc.larkSplitViewController {
            if split.isCollapsed {
                finish?(false, false)
                LarkSplitViewController.Tracker.trackFullScreenItemShow(
                    scene: vc.fullScreenSceneBlock?(), isFold: true
                )
            } else if split.splitMode == .secondaryOnly {
                finish?(true, true)
                LarkSplitViewController.Tracker.trackFullScreenItemShow(
                    scene: vc.fullScreenSceneBlock?(), isFold: false
                )
            } else {
                finish?(true, false)
                LarkSplitViewController.Tracker.trackFullScreenItemShow(
                    scene: vc.fullScreenSceneBlock?(), isFold: true
                )
            }
        }
    }
}
