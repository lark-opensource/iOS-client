//
//  FeedPresentProcessor+UIPopoverPresentationControllerDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/8/5.
//

import UIKit
import Foundation
extension FeedPresentProcessor: UIPopoverPresentationControllerDelegate {

    /// 对于popoverVC，点击popover会询问是否dismiss，需要将popoverPresentVC的delegate收敛在这里，统一由Processor管理dismiss
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        defer {
            dismissCurrentIfNeeded(animate: true,
                                   checkType: nil,
                                   handleInnerTriggerDismiss: true,
                                   completion: nil)
        }
        return false
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    #if canImport(CryptoKit)
    @available(iOS 13.0, *)
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        defer {
            dismissCurrentIfNeeded(animate: true,
                                   checkType: nil,
                                   handleInnerTriggerDismiss: true,
                                   completion: nil)
        }
        return false
    }
    #endif
}
