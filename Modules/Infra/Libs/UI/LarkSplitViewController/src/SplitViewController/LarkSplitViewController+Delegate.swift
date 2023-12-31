//
//  SplitViewController+Delegate.swift
//  SplitViewControllerDemo
//
//  Created by Yaoguoguo on 2022/8/15.
//

import Foundation
import UIKit

public protocol SplitViewControllerProxy: AnyObject {
    func splitViewControllerDidCollapse(_ svc: SplitViewController)

    func splitViewControllerDidExpand(_ svc: SplitViewController)

    func splitViewController(_ svc: SplitViewController, willShow column: SplitViewController.Column)

    func splitViewController(_ svc: SplitViewController, willHide column: SplitViewController.Column)

    func splitViewController(_ svc: SplitViewController, willChangeTo splitMode: SplitViewController.SplitMode)

    func splitViewController(_ svc: SplitViewController, didChangeTo splitMode: SplitViewController.SplitMode)

    func splitViewControllerInteractivePresentationGestureWillBegin(_ svc: SplitViewController)

    func splitViewControllerInteractivePresentationGestureDidEnd(_ svc: SplitViewController)
}

public extension SplitViewControllerProxy {
    func splitViewControllerDidCollapse(_ svc: SplitViewController) {}

    func splitViewControllerDidExpand(_ svc: SplitViewController) {}

    func splitViewController(_ svc: SplitViewController, willShow column: SplitViewController.Column) {}

    func splitViewController(_ svc: SplitViewController, willHide column: SplitViewController.Column) {}

    func splitViewController(_ svc: SplitViewController, willChangeTo splitMode: SplitViewController.SplitMode) {}

    func splitViewController(_ svc: SplitViewController, didChangeTo splitMode: SplitViewController.SplitMode) {}

    func splitViewControllerInteractivePresentationGestureWillBegin(_ svc: SplitViewController) {}

    func splitViewControllerInteractivePresentationGestureDidEnd(_ svc: SplitViewController) {}
}

public protocol SplitViewControllerDelegate: SplitViewControllerProxy {

    // Asks the delegate to provide the column to display after the split view interface collapses.
    func splitViewController(_ svc: SplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: SplitViewController.Column) -> SplitViewController.Column

    func splitViewController(_ svc: SplitViewController,
                             splitModeForExpandingToProposedSplitMode proposedSplitMode: SplitViewController.SplitMode) -> SplitViewController.SplitMode

    // displayMode变成.masterAndDetail时，决定viewController是否能被merge
    // 默认为true
    // 如果返回false, 该VC不会被加入到masterNavigation，还保持在detailNavigation；注意，返回false，会导致合并再拆分后，detailNavi里VC的顺序层次发生变化
    // 如果返回true, 该VC会从detailNavigation中移除，加入到masterNavigation
    func splitViewController(_ svc: SplitViewController, isMergeFor viewController: UIViewController) -> Bool

    func splitViewControllerCanMergeSide(_ svc: SplitViewController) -> Bool

    func splitViewControllerCanMergeCompact(_ svc: SplitViewController) -> Bool
}

public extension SplitViewControllerDelegate {

    func splitViewController(_ svc: SplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: SplitViewController.Column) -> SplitViewController.Column {
        return .compact
    }

    func splitViewController(_ svc: SplitViewController,
                             splitModeForExpandingToProposedSplitMode proposedSplitMode: SplitViewController.SplitMode) -> SplitViewController.SplitMode {
        return .secondaryOnly
    }

    func splitViewControllerDidCollapse(_ svc: SplitViewController) {}

    func splitViewControllerDidExpand(_ svc: SplitViewController) {}

    func splitViewController(_ svc: SplitViewController, willShow column: SplitViewController.Column) {}

    func splitViewController(_ svc: SplitViewController, willHide column: SplitViewController.Column) {}

    func splitViewController(_ svc: SplitViewController, willChangeTo splitMode: SplitViewController.SplitMode) {}

    func splitViewController(_ svc: SplitViewController, didChangeTo splitMode: SplitViewController.SplitMode) {}

    func splitViewControllerInteractivePresentationGestureWillBegin(_ svc: SplitViewController) {}

    func splitViewControllerInteractivePresentationGestureDidEnd(_ svc: SplitViewController) {}

    func splitViewController(_ svc: SplitViewController, isMergeFor viewController: UIViewController) -> Bool { return true }

    func splitViewControllerCanMergeSide(_ svc: SplitViewController) -> Bool { return true }

    func splitViewControllerCanMergeCompact(_ svc: SplitViewController) -> Bool { return true }
}
