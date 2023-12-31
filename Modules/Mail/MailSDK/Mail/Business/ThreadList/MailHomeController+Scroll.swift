//
//  MailHomeController+Scroll.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/3/1.
//

import Foundation
import UIKit

// MARK: - UIScrollViewDelegate
extension MailHomeController {

    func _scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tableView else {
            return
        }
        if !viewModel.hasFirstLoaded {
            return
        }
        changeTableView2()
    }

    private func changeTableView2() {
        guard !isMultiSelecting else { return }
        if lastDragOffset != nil {
            let distance = tableView.contentOffset.y - lastContentOffsetY
            if distance > 0, tableView.contentOffset.y >= naviHeight {
                clearContentsBeforeAsynchronouslyDisplay = asyncRender
                displaysAsynchronously = asyncRender
                showLarkNavbarFlag.accept(false)
            } else {
                showLarkNavbarFlag.accept(true)
                if (abs(tableView.contentOffset.y) < naviHeight || tableView.contentOffset.y < 0),
                   !header.showingRefreshAnimation {
                    setInset()
                }
            }
        }
        lastContentOffsetY = tableView.contentOffset.y
    }

    func getTopViewHeight() -> CGFloat {
        let multiAccountHeight: CGFloat = multiAccountView.isDescendant(of: view) ? MailThreadListConst.mulitAccountViewHeight : 0
        var naviOffset = naviHeight
        if let naviBar = naviBar {
            naviOffset = naviBar.frame.minY + naviOffset
        }
        return naviOffset + multiAccountHeight
    }
    
    func getTopViewHeightOld() -> CGFloat {
        return naviHeight + (multiAccountView.isDescendant(of: view) ? CGFloat(48) : 0)
    }

    func _scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastDragOffset = scrollView.contentOffset.y
    }

    func _scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            lastDragOffset = nil
            clearContentsBeforeAsynchronouslyDisplay = false
            displaysAsynchronously = false
            preloadVisableIndexsIfNeed()
        }
    }

    func _scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastDragOffset = nil
        clearContentsBeforeAsynchronouslyDisplay = false
        displaysAsynchronously = false
        preloadVisableIndexsIfNeed()
    }

    func _scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        shouldCheckNavigationBarVisibility = true
        preloadVisableIndexsIfNeed()
    }

    func _scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard asyncRender && Display.oldSeries() else { // 开启异步渲染下，为了防止滑动过快的明显白屏，需要进行一些极限情况下的限速
            return
        }
        let velocityLimit: Double = 3.5
        if velocity.y > velocityLimit {
            scrollView.decelerationRate = .fast
        } else {
            scrollView.decelerationRate = .normal
        }
    }

    func preloadVisableIndexsIfNeed() {
        DispatchQueue.main.async {
            guard let indexPaths = self.tableView.indexPathsForVisibleRows else { return }
            self.viewModel.preloadVisableIndexsIfNeed(indexPaths: indexPaths)
        }

    }
}

extension MailHomeController {

    func _scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollingToTop = true
        return true
    }

    func _scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        showLarkNavbarFlag.accept(true)
        scrollingToTop = false
    }

    func srcollToTop(completion: (() -> Void)? = nil) {
        if let headerFrame = self.tableView.tableHeaderView?.frame {
            if headerFrame.height > 1 {
                setInset()
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.ultraShort) {
                    self.tableView.scrollRectToVisible(headerFrame, animated: true)
                    completion?()
                }
            } else if viewModel.datasource.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.ultraShort) {
                    self.tableView.btd_scrollToTop()
                    completion?()
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.ultraShort) {
                guard self.viewModel.datasource.count > 0 else { return }
                self.tableView.btd_scrollToTop()
                completion?()
            }
        }
    }
}
