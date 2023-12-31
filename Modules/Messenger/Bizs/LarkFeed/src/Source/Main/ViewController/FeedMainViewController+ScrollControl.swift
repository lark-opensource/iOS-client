//
//  FeedMainViewController+ScrollControl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import UIKit
import Foundation
import RustPB

enum HeaderVisibleStatus: Int {
    case invisible = 0, // 不可见
         partVisible,  // 展示部分
         fullVisible  // 展示完整
}

enum ScrollState {
    case scrollViewCanScroll
    case tableViewCanScroll
}

// MARK: 判断哪个scroll可以滑动的逻辑
extension FeedMainViewController {
    func observeOffsetChange() {
        guard let currentScrollView = moduleVCContainerView.currentScrollView else { return }
        // 解决手势冲突
        mainScrollView.innerScrollView = currentScrollView
        currentScrollView.outerScrollView = mainScrollView
        let task = { [weak self, weak currentScrollView] (scrollView: UIScrollView, oldOffset: CGPoint, newOffset: CGPoint) -> Bool in
            guard let self = self, let cscrollView = currentScrollView else { return false }
            return self.judgeIsScroll(scrollView: scrollView,
                                      moduleScrollView: cscrollView,
                                      oldOffset: oldOffset,
                                      newOffset: newOffset)
        }
        mainScrollView.contentOffsetChanging = task
        currentScrollView.contentOffsetChanging = task
    }

    func judgeIsScroll(scrollView: UIScrollView,
                       moduleScrollView: UIScrollView,
                       oldOffset: CGPoint,
                       newOffset: CGPoint) -> Bool {
        guard newOffset != oldOffset else { return false }

        // 滑动方向，ture为上滑，false为下拉
        let isScrollUP = newOffset.y > oldOffset.y
        // 临界值
        let filterHeight = filterTabViewModel.isSupportCeiling ? 0 : filterTabViewModel.viewHeight
        let headerHeight = headerView.bounds.size.height
        let criticalValue = headerHeight + filterHeight
        // 使用旧值判断
        let oldScrollOffsetY: CGFloat
        let oldListOffsetY: CGFloat

        if scrollView === self.mainScrollView {
            oldScrollOffsetY = oldOffset.y
            oldListOffsetY = moduleScrollView.contentOffset.y
        } else {
            oldScrollOffsetY = self.mainScrollView.contentOffset.y
            oldListOffsetY = oldOffset.y
        }
        /*
         主要是以下两个主要条件：
            1. headerVisibleStatus：header的可见状态
            2. isListTop：moduleScrollView的y值是否在自身的顶部

         疑问点：
            1. 在即将要进行检测是否可滑动时，先调用了[super setContentOffset: newOffset]，其实不应该先调用，而是等结果再来决定是否。但是尝试了下，动画效果不行，offset变化幅度太大
            1. 使用旧值作为判断是否可以滑动的条件，却没有使用新值判断，需要进一步思考这块
            2. 使用旧值而不是新值来禁止滑动，即使加上了纠偏，但也需要进一步思考
         */
        let headerVisibleStatus: HeaderVisibleStatus
        if oldScrollOffsetY <= 0 {
            headerVisibleStatus = .fullVisible
        } else if oldScrollOffsetY > 0 && oldScrollOffsetY < criticalValue {
            headerVisibleStatus = .partVisible
        } else {
            headerVisibleStatus = .invisible
        }
        let isListTop = oldListOffsetY <= 0

        // 默认scrollView可滑动
        var scrollState: ScrollState = .scrollViewCanScroll
        switch headerVisibleStatus {
        case .fullVisible:
            if !isListTop && !isScrollUP {
                // 当header全部可见时 & tableview的y值没有处于顶部时 & 下拉时
                scrollState = .tableViewCanScroll
            }
        case .partVisible:
            break
        case .invisible:
            if isListTop {
                if isScrollUP {
                    // 当header不显示时 & 当tableview的y值处于顶部时 & 上滑时：tableview可以滑动
                    scrollState = .tableViewCanScroll
                }
            } else {
                // 当header不显示时 & 当tableview的y值没有处于顶部时：tableview可以滑动
                scrollState = .tableViewCanScroll
            }
        }

        // 兜底，当header不显示时，直接让tableView可以滑动
        if headerHeight <= 0 {
            scrollState = .tableViewCanScroll
        }

        do {
            if (scrollState == .tableViewCanScroll && scrollView === moduleScrollView) ||
                (scrollState == .scrollViewCanScroll && scrollView === self.mainScrollView) {
                scrollDirection = newOffset.y > oldOffset.y ? .up : .down
            }
        }
        switch scrollState {
        case .scrollViewCanScroll:
            let scrollCanScroll = scrollView === self.mainScrollView
            return scrollCanScroll
        case .tableViewCanScroll:
            let tableCanScroll = scrollView === moduleScrollView
            return tableCanScroll
        }
    }
}
