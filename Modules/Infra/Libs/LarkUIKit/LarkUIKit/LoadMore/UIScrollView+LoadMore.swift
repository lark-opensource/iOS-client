//
//  UIScrollView+LoadMore.swift
//  LarkUIKit
//
//  Created by zhuchao on 2017/9/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

private var pullUpBackgroundViewKey: Void?
private var pullDownBackgroundViewKey: Void?

private var pullUpStateChangeBlockKey: String = ""
private var pullDownStateChangeBlockKey: String = ""

extension UIScrollView {
    /// Infinitiy scroll associated property
    public var bottomLoadMoreView: PullUpBackgroundView? {
        get { return (objc_getAssociatedObject(self, &pullUpBackgroundViewKey) as? PullUpBackgroundView) }
        set(newValue) { objc_setAssociatedObject(self, &pullUpBackgroundViewKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }

    public var pullUpStateChangeBlock: ((LoadMoreState, LoadMoreState) -> Void)? {
        get { return (objc_getAssociatedObject(self, &pullUpStateChangeBlockKey) as? ((LoadMoreState, LoadMoreState) -> Void)) }
        set(newValue) {
            objc_setAssociatedObject(self, &pullUpStateChangeBlockKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var isBottomLoadMoreEnable: Bool {
        guard let loadMoreView = self.bottomLoadMoreView else {
            return false
        }
        return loadMoreView.enabled
    }

    public func addBottomLoadMoreView(
        height: CGFloat = 44.0,
        infiniteScrollActionImmediatly: Bool = true,
        handler: @escaping (() -> Void)
    ) {
        self.addBottomLoadMoreView(
            height: height,
            infiniteScrollActionImmediatly: infiniteScrollActionImmediatly,
            loadingView: nil,
            handler: handler)
    }

    public func addBottomLoadMoreView(
        height: CGFloat = 44.0,
        infiniteScrollActionImmediatly: Bool = true,
        loadingView: LoadingViewProtocol? = nil,
        handler: @escaping (() -> Void)
    ) {
//        if let bottomView = self.bottomLoadMoreView, bottomView.scrollView == self {
//            bottomView.resetFrame()
//            return
//        }
        self.removeBottomLoadMore()
        let loadMoreView = PullUpBackgroundView(height: height, scrollView: self, loadingView: loadingView)
        loadMoreView.handler = handler
        loadMoreView.preserveContentInset = false
        loadMoreView.callInfiniteScrollActionImmediatly = infiniteScrollActionImmediatly
        loadMoreView.stateChangeBlock = self.pullUpStateChangeBlock
        self.addSubview(loadMoreView)
        self.bottomLoadMoreView = loadMoreView
    }

    public func endBottomLoadMore(hasMore: Bool) {
        if hasMore {
            self.endBottomLoadMore()
        } else {
            self.enableBottomLoadMore(false)
        }
    }

    public func endBottomLoadMore() {
        self.bottomLoadMoreView?.endInfiniteScrolling(withStoppingContentOffset: false)
    }

    public func enableBottomLoadMore(_ isEnable: Bool) {
        self.bottomLoadMoreView?.enabled = isEnable
    }

    public func removeBottomLoadMore() {
        self.bottomLoadMoreView?.removeFromSuperview()
        self.bottomLoadMoreView = nil
    }
}

extension UIScrollView {
    /// Infinitiy scroll associated property
    public var topLoadMoreView: PullDownRefreshProtocol? {
        get {
            return objc_getAssociatedObject(self, &pullDownBackgroundViewKey) as? PullDownRefreshProtocol
        }
        set {
            objc_setAssociatedObject(
                self,
                &pullDownBackgroundViewKey,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN
            )
        }
    }

    public var pullDownStateChangeBlock: ((LoadMoreState, LoadMoreState) -> Void)? {
        get {
            return (objc_getAssociatedObject(self, &pullDownStateChangeBlockKey) as? ((LoadMoreState, LoadMoreState) -> Void))
        }
        set(newValue) {
            objc_setAssociatedObject(self, &pullDownStateChangeBlockKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    public func addTopLoadMoreView(height: CGFloat,
                                   infiniteScrollActionImmediatly: Bool = true,
                                   triggerOffSet: CGFloat, handler: @escaping (() -> Void)) {
//        if let topView = self.topLoadMoreView, topView.scrollView == self {
//            topView.resetFrame()
//            return
//        }
        self.removeTopLoadMore()
        let loadMoreView = PullDownBackgroundView(height: height, scrollView: self, triggerOffSet: triggerOffSet)
        loadMoreView.handler = handler
        loadMoreView.preserveContentInset = false
        loadMoreView.callInfiniteScrollActionImmediatly = infiniteScrollActionImmediatly
        loadMoreView.stateChangeBlock = self.pullDownStateChangeBlock
        self.addSubview(loadMoreView)
        self.topLoadMoreView = loadMoreView
    }

    public func addRefreshView(height: CGFloat, handler: @escaping (() -> Void)) {
        self.removeTopLoadMore()
        let loadMoreView = RefreshBackgroundView(height: height, scrollView: self)
        loadMoreView.handler = handler
        self.addSubview(loadMoreView)
        self.topLoadMoreView = loadMoreView
    }

    public func addTopLoadMoreView(height: CGFloat, infiniteScrollActionImmediatly: Bool = true, handler: @escaping (() -> Void)) {
        self.addTopLoadMoreView(height: height,
                                infiniteScrollActionImmediatly: infiniteScrollActionImmediatly,
                                triggerOffSet: 0,
                                handler: handler)
    }

    public func endTopLoadMore(hasMore: Bool) {
        if hasMore {
            self.endTopLoadMore()
        } else {
            self.enableTopLoadMore(hasMore)
        }
    }

    public func endTopLoadMore() {
        self.topLoadMoreView?.endRefresh()
    }

    public func enableTopLoadMore(_ isEnable: Bool) {
        self.topLoadMoreView?.enabled = isEnable
    }

    public func removeTopLoadMore() {
        self.topLoadMoreView?.removeFromSuperview()
        self.topLoadMoreView = nil
    }
}
