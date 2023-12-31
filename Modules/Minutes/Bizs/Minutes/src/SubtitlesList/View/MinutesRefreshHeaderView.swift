//
//  MinutesPullToRefresh.swift
//  Minutes
//
//  Created by yangyao on 2021/1/26.
//

import ESPullToRefresh

class MinutesRefreshHeaderView: ESRefreshHeaderView {
    public override func stop() {
        guard let scrollView = scrollView else {
            return
        }

        // ignore observer
        self.ignoreObserver(true)

        self.animator.refreshAnimationEnd(view: self)

        // Back state
        scrollView.contentInset.top = self.scrollViewInsets.top
        scrollView.contentOffset.y = -self.scrollViewInsets.top
        self.animator.refresh(view: self, stateDidChange: .pullToRefresh)

        self._isRefreshing = false
        self._isAutoRefreshing = false

        scrollView.contentInset.top = self.scrollViewInsets.top
        self.previousOffset = scrollView.contentOffset.y
        // un-ignore observer
        self.ignoreObserver(false)
    }
}

public extension ES where Base: UIScrollView {
    @discardableResult
    func addMinutesPullToRefresh(animator: ESRefreshProtocol & ESRefreshAnimatorProtocol, handler: @escaping ESRefreshHandler) -> ESRefreshHeaderView {
        removeRefreshHeader()
        let header = MinutesRefreshHeaderView(frame: CGRect.zero, handler: handler, animator: animator)
        let headerH = animator.executeIncremental
        header.frame = CGRect.init(x: 0.0, y: -headerH /* - contentInset.top */, width: self.base.bounds.size.width, height: headerH)
        self.base.addSubview(header)
        self.base.header = header
        return header
    }
}
