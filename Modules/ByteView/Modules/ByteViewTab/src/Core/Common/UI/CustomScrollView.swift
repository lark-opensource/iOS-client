//
//  CustomScrollView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/2/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI

/// Refer to LarkFeed
class EmbeddableScrollView: UIScrollView, UIGestureRecognizerDelegate {

    weak var innerTableView: UITableView?

    var contentOffsetDidChange: ((UIScrollView, CGPoint, CGPoint) -> Bool)?

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let tableView = innerTableView else { return false }
        return tableView.panGestureRecognizer == otherGestureRecognizer
    }

    override var contentOffset: CGPoint {
        get {
            super.contentOffset
        }
        set {
            guard let innerTableView = innerTableView,
                  let contentOffsetDidChange = contentOffsetDidChange,
                  self.isDragging || innerTableView.isDragging else {
                super.contentOffset = newValue
                return
            }

            // 手势 调用
            let oldOffset = super.contentOffset
            let newOffset = newValue
            guard oldOffset != newOffset else {
                return
            }

            super.contentOffset = newOffset

            let shouldChange = contentOffsetDidChange(self, oldOffset, newOffset)
            if shouldChange {
                // 可以滑动
            } else {
                // 禁止滑动，维持原来的位置
                // 纠偏
                var y: CGFloat = oldOffset.y
                let max: CGFloat = self.contentSize.height - self.bounds.size.height
                if y > max {
                    y = max
                }
                let min: CGFloat = -self.contentInset.top
                if y < min {
                    y = min
                }
                super.contentOffset = CGPoint(x: oldOffset.x, y: y)
            }
        }
    }

    func setContentOffsetWithoutNotify(_ contentOffset: CGPoint) {
        super.contentOffset = contentOffset
    }
}

class EmbeddedTableView: BaseTableView, UIGestureRecognizerDelegate {

    weak var outerScrollView: UIScrollView?

    var contentOffsetDidChange: ((UITableView, CGPoint, CGPoint) -> Bool)?

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView = outerScrollView else { return false }
        return scrollView.panGestureRecognizer == otherGestureRecognizer
    }

    override var contentOffset: CGPoint {
        get {
            super.contentOffset
        }
        set {
            guard let outerScrollView = outerScrollView,
                  let contentOffsetDidChange = self.contentOffsetDidChange,
                  self.isDragging || outerScrollView.isDragging else {
                super.contentOffset = newValue
                return
            }
            // 手势 调用
            let oldOffset = super.contentOffset
            let newOffset = newValue
            guard oldOffset != newOffset else {
                return
            }

            super.contentOffset = newOffset

            let shouldChange = contentOffsetDidChange(self, oldOffset, newOffset)
            if shouldChange {
                // 可以滑动
            } else {
                // 禁止滑动，维持原来的位置
                var y: CGFloat = oldOffset.y
                let min: CGFloat = 0.0
                if y < min {
                    y = min
                }
                super.contentOffset = CGPoint(x: oldOffset.x, y: y)
            }
        }
    }

    func setContentOffsetWithoutNotify(_ contentOffset: CGPoint) {
        super.contentOffset = contentOffset
    }
}
