//
//  CategoryScrollView.swift
//  Moment
//
//  Created by liluobin on 2021/5/10.
//

import Foundation
import UIKit
import RxSwift

final class LinkageScrollView: UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    var lastOffSet: CGPoint = .zero
    var subTableView: MomentLinkagePostTableView?
    var maxOffSetY: CGFloat = 0
    var didScrollCallBack: ((CGPoint) -> Void)?

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view is MomentLinkagePostTableView {
            return true
        }
        return false
    }
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func bindSubTableView(_ tableView: MomentLinkagePostTableView, maxOffSet: CGFloat) {
        self.subTableView = tableView
        self.maxOffSetY = maxOffSet
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollCallBack?(scrollView.contentOffset)
        guard let displayTableView = self.subTableView,
              !contentOffset.equalTo(lastOffSet) else {
            return
        }
        let contentOffsetY = contentOffset.y
        /// 上滑
        if contentOffsetY >= lastOffSet.y {
            /// 向上滑动超出头部 当前已经不能再滑动了 子tableView滑动
            if contentOffsetY >= maxOffSetY {
                displayTableView.canMove = true
                contentOffset = CGPoint(x: 0, y: maxOffSetY)
            } else {
                /// 上滑状态 优先让subTableView还原
                if displayTableView.contentOffset.y < 0 {
                    displayTableView.canMove = true
                    contentOffset = lastOffSet
                } else {
                    displayTableView.canMove = false
                }
            }
        /// 下滑
        } else {
            /// 向下滑动超出头部 当前已经不能再滑动了 子tableView滑动
            if contentOffsetY <= 0 {
                displayTableView.canMove = true
                contentOffset = .zero
            } else {
                // 子View不能滑动了 自己滑
                if displayTableView.contentOffset.y <= 0 {
                    displayTableView.canMove = false
                } else {
                // 子View可以滑动 子View滑
                    displayTableView.canMove = true
                    contentOffset = lastOffSet
                }
            }
        }
        lastOffSet = contentOffset
    }
}
