//
//  InfiniteScrollView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/7.
//  Copyright © 2017年 linlin. All rights reserved.
//  Inspired by https://developer.apple.com/library/content/samplecode/StreetScroller/Introduction/Intro.html
import UIKit
import CalendarFoundation
import LarkDatePickerView

class PageableInfiniteScrollView: InfiniteScrollView {
    var pageWidth: CGFloat
    private let pageCount: Int = 2_000_000

    init(pageWidth: CGFloat) {
        self.pageWidth = pageWidth
        super.init()
        self.isPagingEnabled = true
    }

    var startOffset: CGPoint {
        return CGPoint(x: CGFloat(pageCount) / 2.0 * self.pageWidth, y: 0.0)
    }

    func currentPage() -> Int {
        guard pageWidth != 0 else {
            return 0
        }
        let offSet = self.contentOffset.x - self.startOffset.x
        let page = floor((offSet - pageWidth / 2) / pageWidth) + 1
        return Int(page)
    }

    func scrollToPage(_ page: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if currentPage() == page {
            completion?(false)
            return
        }
        let x = self.startOffset.x + CGFloat(page) * self.frame.width
        let offset = CGPoint(x: x, y: 0)
        if animated {
            UIView.animate(withDuration: 0.15, animations: {
                self.contentOffset = offset
            }, completion: completion)
        } else {
            self.contentOffset = offset
            completion?(true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func defaultContentSize() -> CGSize {
        return CGSize(width: CGFloat(pageCount) * self.pageWidth, height: self.bounds.height)
    }

    override func recenterIfNeed() {
        if self.contentOffset.x == 0 {
            self.contentOffset = CGPoint(x: CGFloat(pageCount) / 2.0 * self.pageWidth, y: 0.0)
        }
    }
}

/// 需要特殊化 缓存两侧没有显示的页面
final class DaysViewInfiniteScrollView: PageableInfiniteScrollView, UIGestureRecognizerDelegate {

    /// 前后各缓存页面的数量 比如1 则其实一共缓存了3页
    var cachePageCount: Int
    private let hasLeftEdge: Bool

    init(pageWidth: CGFloat, cachePageCount: Int = 1, hasLeftEdge: Bool = true) {
        self.cachePageCount = cachePageCount
        self.hasLeftEdge = hasLeftEdge
        super.init(pageWidth: pageWidth)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func relayoutForiPad(newWidth: CGFloat) {
        for view in self.visibleViews {
            if let panel = view as? ArrangementPanel {
                panel.relayout(newWidth: newWidth)
            }
        }
    }

    override func shouldPlaceNewViewOnRight(rightEdge: CGFloat, maximumVisibleX: CGFloat) -> Bool {
        return rightEdge < maximumVisibleX + pageWidth * CGFloat(cachePageCount)
    }

    override func shouldPlaceNewViewOnLeft(leftEdge: CGFloat, minimumVisibleX: CGFloat) -> Bool {
        return leftEdge > minimumVisibleX - pageWidth * CGFloat(cachePageCount)
    }

    override func shouldRemoveLastView(originX: CGFloat, maximumVisibleX: CGFloat) -> Bool {
        return originX >= maximumVisibleX + pageWidth * CGFloat(cachePageCount)
    }

    override func shouldRemoveFirstView(maxX: CGFloat, minimumVisibleX: CGFloat) -> Bool {
        return maxX <= minimumVisibleX - pageWidth * CGFloat(cachePageCount)
    }

    /// 使侧边栏可以通过手势划出
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !hasLeftEdge { return true }
        let location = gestureRecognizer.location(in: self)
        // 预留40的边距来划出侧边栏
        if CGFloat(Int(location.x) % Int(pageWidth)) < 46 {
            return false
        }
        return true
    }
}
