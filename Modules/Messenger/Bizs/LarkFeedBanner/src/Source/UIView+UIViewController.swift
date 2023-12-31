//
//  UIView+UIViewController.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/6/17.
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
        FeedBannerServiceImpV2.logger.error("Can not find parentVC in limit depth: \(parentResponder)")
        return nil
    }

    var bannerDependency: FeedBannerDependency? {
        parentVC as? FeedBannerDependency
    }
}
