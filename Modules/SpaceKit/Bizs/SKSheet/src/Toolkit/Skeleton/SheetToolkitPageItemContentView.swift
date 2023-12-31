//
//  SheetToolkitPageItemContentView.swift
//  SpaceKit
//
//  Created by Webster on 2019/11/11.
//

import UIKit

class SyncScrollContext {
    var maxOffsetY: CGFloat = 0
    var outerOffset: CGPoint = CGPoint.zero
    var innerOffset: CGPoint = CGPoint.zero
}

/// SheetToolkitPageView里面同步滑动的ScrollView需要实现的协议
protocol SheetToolkitPageItemContentViewSyncable: AnyObject {
    var contentOffset: CGPoint { get set }
    var syncScrollContext: SyncScrollContext? { get set }
}

/// 获取ViewController的代理
protocol SheetToolkitPageViewControllerDelegate: AnyObject {
    func childViewController(atIndex index: Int) -> UIViewController
    func parentViewController() -> UIViewController
}

/// 获取数据源的代理
protocol SheetToolkitPageViewDelegate: AnyObject {
    func numberOfItems() -> Int
    func vcScrollViewDidScroll(_ scrollView: UIScrollView)
    func vcScrollViewDidEndScrollAnimation(_ scrollView: UIScrollView) // called when a programmatic-generated scroll finishes
    func vcScrollViewDidEndDecelerating(_ scrollView: UIScrollView) // called when a user-swipe scroll finishes
}

class SheetToolkitPageItemContentView: UIScrollView, SheetToolkitPageItemContentViewSyncable {
    var syncScrollContext: SyncScrollContext?
    override var contentOffset: CGPoint {
        didSet {
            if contentOffset.y != oldValue.y {
                guard let syncScrollContext = syncScrollContext else { return }
                if syncScrollContext.outerOffset.y < syncScrollContext.maxOffsetY {
                    contentOffset.y = -contentInset.top
                }
                syncScrollContext.innerOffset = contentOffset
            }
        }
    }
}

extension SheetToolkitPageItemContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view is UICollectionView
        || otherGestureRecognizer.view is UICollectionView {
            return false
        }
        return true
    }
}
