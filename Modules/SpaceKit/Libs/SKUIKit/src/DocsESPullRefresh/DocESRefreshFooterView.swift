//
//  DocESRefreshView.swift
//  SpaceKit
//
//  Created by litao_dev on 2020/5/28.
//
//  Included OSS: pull-to-refresh
//  Copyright (c) 2016 lihao
//  spdx license identifier: MIT

import Foundation
import ESPullToRefresh

class DocESRefreshFooterView: ESRefreshFooterView {
    convenience init(frame: CGRect, handler: @escaping ESRefreshHandler) {
        self.init(frame: frame)
        self.handler = handler
        self.animator = DocESRefreshFooterAnimator()
    }

    override func sizeChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey: Any]?) {
        guard let scrollView = scrollView else { return }
        super.sizeChangeAction(object: object, change: change)
        let targetY = scrollView.contentSize.height
        if self.frame.origin.y != targetY {
            var rect = self.frame
            rect.origin.y = targetY
            self.frame = rect
        }
    }

    override func offsetChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey: Any]?) {
        guard let scrollView = scrollView else {
            return
        }

        super.offsetChangeAction(object: object, change: change)

        guard isRefreshing == false && isAutoRefreshing == false && noMoreData == false && isHidden == false else {
            // 正在loading more或者内容为空时不相应变化
            return
        }

        if scrollView.contentSize.height <= 0.0 || scrollView.contentOffset.y + scrollView.contentInset.top <= 0.0 {
            return
        }

        if scrollView.contentSize.height + scrollView.contentInset.top > scrollView.bounds.size.height {
            // 内容超过一个屏幕 计算公式，判断是不是在拖在到了底部
            if scrollView.contentSize.height - scrollView.contentOffset.y + scrollView.contentInset.bottom < scrollView.bounds.size.height {
                self.animator.refresh(view: self, stateDidChange: .refreshing)
                self.startRefreshing()
            }
        } else {
            //内容没有超过一个屏幕，这时拖拽高度大于1/2footer的高度就表示请求上拉
            if scrollView.contentOffset.y + scrollView.contentInset.top >= animator.trigger / 2.0 {
                self.animator.refresh(view: self, stateDidChange: .refreshing)
                self.startRefreshing()
            }
        }
    }

    override func stop() {
        guard let scrollView = scrollView else {
            return
        }

        self.animator.refreshAnimationEnd(view: self)

        // Back state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
        }, completion: { (_) in
            if self.noMoreData == false {
                self.animator.refresh(view: self, stateDidChange: .pullToRefresh)
            }
            super.stop()
        })

        // Stop deceleration of UIScrollView. When the button tap event is caught, you read what the [scrollView contentOffset].x is, and set the offset to this value with animation OFF.
        // http://stackoverflow.com/questions/2037892/stop-deceleration-of-uiscrollview
        if scrollView.isDecelerating {
            var contentOffset = scrollView.contentOffset
            contentOffset.y = min(contentOffset.y, scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.bottom)
            if contentOffset.y < -scrollView.contentInset.top {
                contentOffset.y = -scrollView.contentInset.top
            }
            UIView.animate(withDuration: 0.1, animations: {
                scrollView.setContentOffset(contentOffset, animated: false)
            })
        }

    }
}

class DocESRefreshHeaderView: ESRefreshHeaderView {
    convenience init(frame: CGRect, handler: @escaping ESRefreshHandler) {
        self.init(frame: frame)
        self.handler = handler
        self.animator = DocESRefreshHeaderAnimator()
    }
}
