//
//  Extension+LKSplitViewController.swift
//  LarkNavigator
//
//  Created by lixiaorui on 2019/9/17.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LarkSplitViewController

extension UIViewController: LKSplitVCDelegate {

    public var lkTopMost: UIViewController? {
        return (self as? SplitViewController)?.topMost
    }

    public var lkTabIdentifier: String? {
        guard let split = self as? SplitViewController else { return nil }
        let master = split.sideNavigationController
        let masterVC = (master as? UINavigationController)?.viewControllers.first
        return (masterVC ?? master)?.identifier
    }

}
