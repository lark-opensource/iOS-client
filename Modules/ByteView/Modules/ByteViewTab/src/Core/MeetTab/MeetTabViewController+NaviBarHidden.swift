//
//  MeetTabViewController+NaviBarHidden.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import UIKit
import RxSwift

extension MeetTabViewController {

    func toggleNavigationBar(_ scrollView: UIScrollView, _ offsetY: CGFloat) {
        guard shouldCheckNavigationBarVisibility else { return }
        if scrollDirection == .up {
            if (scrollView === self.containerView && offsetY >= naviHeight) ||
                (scrollView === self.tabResultView.tableView && offsetY > 0) { // 防止向下的bounce造成naviBar隐藏
                showNavigationBar(show: false)
            }
        } else if scrollDirection == .down {
            if scrollView === self.tabResultView.tableView {
                let height = self.tabResultView.tableView.frame.size.height
                let contentHeight = self.tabResultView.tableView.contentSize.height
                if offsetY >= contentHeight - height {
                    return // 防止底部向上的bounce造成naviBar显示
                }
            }
            showNavigationBar(show: true)
        }
    }

    // 判断哪个scroll可以滑动的逻辑
    func scrollView(_ scrollView: UIScrollView,
                    didChangeContentOffsetFrom oldOffset: CGPoint,
                    to newOffset: CGPoint) -> Bool {
        guard newOffset != oldOffset else { return false }

        var scrollOffsetY: CGFloat = 0 // 外部scrollView的y值
        var tableViewOffsetY: CGFloat = 0 // 内嵌tableView的y值
        if scrollView === tabResultView.tableView {
            scrollOffsetY = self.containerView.contentOffset.y
            tableViewOffsetY = oldOffset.y
        } else if scrollView === self.containerView {
            scrollOffsetY = oldOffset.y
            tableViewOffsetY = tabResultView.tableView.contentOffset.y
        }
        let isHeaderFullyVisible: Bool = (scrollOffsetY <= 0)
        let headerHeight = headerView.bounds.size.height + noInternetView.bounds.size.height
        let isHeaderViewVisible: Bool = scrollOffsetY < headerHeight // header 是否可见
        let isScrollUp: Bool = newOffset.y > oldOffset.y

        let scrollState = calculateScrollState(isHeaderViewVisible: isHeaderViewVisible,
                                               isHeaderFullyVisible: isHeaderFullyVisible,
                                               isScrollUp: isScrollUp,
                                               tableViewOffsetY: tableViewOffsetY)
        do {
            if (scrollState == .tableViewCanScroll && scrollView === tabResultView.tableView) ||
                (scrollState == .scrollViewCanScroll && scrollView === self.containerView) {
                scrollDirection = isScrollUp ? .up : .down
            }
        }

        switch scrollState {
        case .scrollViewCanScroll:
            let scrollCanScroll = scrollView === self.containerView
            return scrollCanScroll
        case .tableViewCanScroll:
            let tableCanScroll = scrollView === self.tabResultView.tableView
            return tableCanScroll
        }
    }

    private func calculateScrollState(isHeaderViewVisible: Bool,
                                      isHeaderFullyVisible: Bool,
                                      isScrollUp: Bool,
                                      tableViewOffsetY: CGFloat) -> ScrollState {
        /* 逻辑判断
         1. header显示：
             1. Header完全展示
                 1. tableview的y值在顶部：下拉和上滑，scroll可以滑动
                 2. tableview的y值不在顶部：下拉，tableview可以滑动，上滑，scroll可以滑动
             2. Header展示一部分：
                 1. tableview的y值在顶部：下拉和上滑，scroll可以滑动
                 2. tableview的y值不在顶部：下拉和上滑，scroll可以滑动
         2. header不显示：
             1. tableview的y值在顶部：下拉，scroll可以滑动，上滑，tableview可以滑动
             2. tableview的y值不在顶部：下拉和上滑，tableview可以滑动
         */
        var scrollState: ScrollState = .scrollViewCanScroll
        let tableViewIsTop: Bool = tableViewOffsetY <= 0 // 内嵌tableView的y值是否在自身的顶部
        if isHeaderViewVisible {
            // header显示
            if isHeaderFullyVisible {
                // Header完全展示
                if tableViewIsTop {
                    // tableview的y值在顶部
                    if isScrollUp {
                        // 上滑
                        if tableViewOffsetY < 0 {
                            // tableView存在bounce，tableview可以滑动
                            scrollState = .tableViewCanScroll
                        } else {
                            // scroll可以滑动
                            scrollState = .scrollViewCanScroll
                        }
                    } else {
                        // 下拉，tableview可以滑动
                        scrollState = .tableViewCanScroll
                    }
                } else {
                    // tableview的y值不在顶部
                    if isScrollUp {
                        // 上滑，scroll可以滑动
                        scrollState = .scrollViewCanScroll
                    } else {
                        // 下拉，tableview可以滑动
                        scrollState = .tableViewCanScroll
                    }
                }
            } else {
                // Header展示一部分
                scrollState = .scrollViewCanScroll
            }
        } else {
            // header不显示
            if tableViewIsTop {
                // tableview的y值在顶部
                if isScrollUp {
                    // 上滑，tableview可以滑动
                    scrollState = .tableViewCanScroll
                } else {
                    // 下拉，scroll可以滑动
                    scrollState = .scrollViewCanScroll
                }
            } else {
                // tableview的y值不在顶部：下拉和上滑，tableview可以滑动
                scrollState = .tableViewCanScroll
            }
        }
        return scrollState
    }

    func showNavigationBar(show: Bool, animated: Bool = false) {
        guard !isNavigationBarAnimating,
              let isNaviBarShown = self.larkMainViewController?.isLarkNaviBarShown,
              isNaviBarShown != show else { return }
        isNavigationBarAnimating = true
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, animations: {
                self.larkMainViewController?.changeLarkNavigationBarPresentation(show: show, animated: true)
            }, completion: { _ in
                self.isNavigationBarAnimating = false
            })
        } else {
            self.larkMainViewController?.changeLarkNavigationBarPresentation(show: show, animated: false)
            self.isNavigationBarAnimating = false
        }
    }
}
