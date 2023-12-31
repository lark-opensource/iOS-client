//
//  BVPullToRefresh.swift
//  ByteView
//
//  Created by fakegourmet on 2021/4/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import ESPullToRefresh

/// 重写 ESRefreshFooterView 的 start 方法，防止上拉加载跳动
/// https://bytedance.feishu.cn/docs/doccnsu4IK5WmHBuLXpAX6wllAh#
open class BVRefreshFooterView: ESRefreshFooterView {
    public override func start() {
        guard scrollView != nil else { return }
        self.animator.refreshAnimationBegin(view: self)
        self.handler?()
    }
}

public extension ES where Base: UIScrollView {

    @discardableResult
    func addBVInfiniteScrolling(animator: ESRefreshProtocol & ESRefreshAnimatorProtocol, handler: @escaping ESRefreshHandler) -> BVRefreshFooterView {
        removeRefreshFooter()
        let footer = BVRefreshFooterView(frame: CGRect.zero, handler: handler, animator: animator)
        let footerH = footer.animator.executeIncremental
        footer.frame = CGRect.init(x: 0.0, y: self.base.contentSize.height + self.base.contentInset.bottom, width: self.base.bounds.size.width, height: footerH)
        self.base.footer = footer
        self.base.addSubview(footer)
        return footer
    }
}
