//
//  UIView+UIViewController.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/6.
//

import UIKit
extension UIView {
    /// 获取View所在的ViewController
    var parentVC: UIViewController? {
        let maxDepth = 20 // 频控
        var currentDepth = 0
        var parentResponder: UIResponder? = self
        while parentResponder != nil, currentDepth < maxDepth {
            parentResponder = parentResponder?.next
            currentDepth += 1
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        FeedContext.log.error("feedlog. can not find parentVC in limit depth: \(String(describing: parentResponder))")
        return nil
    }

    var horizontalSizeClass: UIUserInterfaceSizeClass? {
        window?.lkTraitCollection.horizontalSizeClass
    }
}
