//
//  PageViewControllerProtocol.swift
//  LarkSegmentController
//
//  Created by KongKaikai on 2018/12/11.
//  Copyright © 2018 KongKaikai. All rights reserved.
//

import UIKit
import Foundation

public protocol PageViewControllerDataSource: AnyObject {

    /// 返回有多少页，如果使用‘segmentControl’，最好返回一致的值
    func numberOfPage(in segmentController: PageViewController) -> Int

    /// 返回Index对应的Controller
    func segmentController(_ controller: PageViewController,
                           controllerAt index: Int) -> PageViewController.InnerController?
}

/// 所有方法作用均参考’UIScrollViewDelegate‘
public protocol PageViewControllerVerticalScrollDelegate: AnyObject {
    func verticalScrollViewDidScroll(_ scrollView: UIScrollView)
    func verticalScrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func verticalScrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func verticalScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func verticalScrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    func verticalScrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}

/// for optional
// swiftlint:disable missing_docs
extension PageViewControllerVerticalScrollDelegate {
    public func verticalScrollViewDidScroll(_ scrollView: UIScrollView) {}
    public func verticalScrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
    public func verticalScrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    public func verticalScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
    public func verticalScrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    public func verticalScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
}
// swiftlint:enable missing_docs
