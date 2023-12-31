//
//  WorkplacePreviewController+LKSplitViewControllerMutiDelegate.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/19.
//

import Foundation
import LarkSplitViewController
import SnapKit

extension WorkplacePreviewController: SplitViewControllerProxy {
    func splitViewController(_ svc: SplitViewController, willChangeTo splitMode: SplitViewController.SplitMode) {

    }

    func splitViewController(_ svc: SplitViewController, didChangeTo splitMode: SplitViewController.SplitMode) {
        Self.logger.info("splitVC did change display mode", additionalData: ["to": "\(splitMode)"])
        switch splitMode {
        case .twoOverSecondary, .twoBesideSecondary, .twoDisplaceSecondary:
            addCloseItem()
            contentSuperWidthConstraint?.deactivate()
            contentWidthConstraint?.update(offset: svc.primaryViewController?.view.frame.width ?? 320.0)
        default:
            contentSuperWidthConstraint?.activate()
        }
    }
}
