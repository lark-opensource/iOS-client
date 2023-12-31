//
//  PullUpBackgroundView.swift
//  LarkUIKit
//
//  Created by zhuchao on 2017/9/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public enum LoadMoreState {
    case none
    case loading
}

public protocol LoadingViewProtocol: UIView {
    func setupLayout()
    func startLoading()
    func stopLoading()
}

private class DefaultLoadingView: UIActivityIndicatorView, LoadingViewProtocol {
    init() {
        super.init(style: .gray)
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }

    func setupLayout() {
        guard let containerView = self.superview else { return }
        self.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.center = CGPoint(x: containerView.bounds.size.width / 2.0, y: containerView.bounds.size.height / 2.0)
        self.hidesWhenStopped = true
        self.color = UIColor.ud.N600
    }

    func startLoading() {
        self.startAnimating()
    }

    func stopLoading() {
        self.stopAnimating()
    }
}

open class PullUpBackgroundView: UIView {
    weak var scrollView: UIScrollView?
    public var state: LoadMoreState = .none {
        didSet {
            if oldValue != state {
                stateChangeBlock?(oldValue, state)
            }
        }
    }

    /// state改变回调函数，入参为 state旧值，state新值
    var stateChangeBlock: ((LoadMoreState, LoadMoreState) -> Void)?
    var handler: (() -> Void)?
    var preserveContentInset: Bool = true {
        didSet {
            if oldValue != preserveContentInset {
                if self.bounds.size.height > 0 {
                    self.resetFrame()
                }
            }
        }
    }

    var enabled: Bool = true {
        didSet {
            if enabled {
                resetFrame()
            } else {
                endInfiniteScrolling(withStoppingContentOffset: false)
            }
            if !shouldShowWhenDisabled {
                isHidden = !enabled
            }
        }
    }

    var shouldShowWhenDisabled: Bool = false {
        didSet {
            if shouldShowWhenDisabled {
                self.isHidden = false
            } else {
                self.isHidden = state == .none
            }
        }
    }

    var bottomOffsetForInfinityScrollTrigger: CGFloat = 0.0
    var callInfiniteScrollActionImmediatly: Bool = true
    var updatingScrollViewContentInset: Bool = false
    var infiniteScrollBottomContentInset: CGFloat = 0.0
    let loadingView: LoadingViewProtocol
    var originalContentInset: UIEdgeInsets = UIEdgeInsets.zero // 初始状态的inset

    init(height: CGFloat, scrollView: UIScrollView, loadingView: LoadingViewProtocol? = nil) {
        self.scrollView = scrollView
        self.loadingView = loadingView ?? DefaultLoadingView()
        super.init(frame: CGRect(x: 0, y: 0, width: scrollView.frame.size.width, height: height))
        self.originalContentInset = scrollView.contentInset // scrollView之前设置好的contentInset
        self.autoresizingMask = [.flexibleWidth]
        self.isHidden = !self.shouldShowWhenDisabled
        self.addSubview(self.loadingView)
        self.loadingView.setupLayout()
        self.resetFrame()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObserver(self.superview)
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.removeObserver(self.superview)
        self.addObserver(newSuperview)
        if newSuperview == nil { // 被从superView上面移走
            self.scrollView?.contentInset = self.originalContentInset
            self.originalContentInset = .zero
        }
    }

    fileprivate func addObserver(_ view: UIView?) {
        guard let scrollView = view as? UIScrollView else {
            return
        }
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
        scrollView.addObserver(self, forKeyPath: "contentSize", options: [.old, .new], context: nil)
        scrollView.addObserver(self, forKeyPath: "frame", options: [.old, .new], context: nil)
        scrollView.addObserver(self, forKeyPath: "contentInset", options: [.old, .new], context: nil)
    }

    fileprivate func removeObserver(_ view: UIView?) {
        view?.removeObserver(self, forKeyPath: "contentOffset")
        view?.removeObserver(self, forKeyPath: "contentSize")
        view?.removeObserver(self, forKeyPath: "frame")
        view?.removeObserver(self, forKeyPath: "contentInset")
    }

    // swiftlint:disable:next block_based_kvo
    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let scrollView = self.scrollView else { return }
        // self sizing 诡异事件
        if scrollView.frame.origin.y < 0 || !enabled || change == nil {
            if keyPath == "contentOffset" || keyPath == "contentSize" || keyPath == "frame" || keyPath == "contentInset" {
                return
            }
        }
        if keyPath == "contentOffset" {
            if let change, let offSet = change[.newKey] as? CGPoint {
                scrollViewDidScroll(offSet)
            }
        } else if keyPath == "contentSize" {
            self.layoutSubviews()
            self.resetFrame()
        } else if keyPath == "frame" {
            self.layoutSubviews()
        } else if keyPath == "contentInset" {
            if !updatingScrollViewContentInset && state == .none {
                if let inset = change![.newKey] as? UIEdgeInsets {
                    self.originalContentInset = inset
                }
                self.resetFrame()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView = self.scrollView else { return }
        let contentHeight: CGFloat = adjustedHeightFromScrollViewContentSize()
        // The lower bound when infinite scroll should kick in
        var actionOffset: CGFloat = contentHeight
            + scrollView.contentInset.bottom
            - scrollView.bounds.size.height
            - bottomOffsetForInfinityScrollTrigger
        // Prevent conflict with pull to refresh when tableView is too short
        actionOffset = max(actionOffset, bottomOffsetForInfinityScrollTrigger)
        // Disable infinite scroll when scroll view is empty
        // Default UITableView reports height = 1 on empty tables
        let hasActualContent: Bool = (scrollView.contentSize.height > 1)
        if scrollView.isDragging && hasActualContent && contentOffset.y > actionOffset {
            if state == .none {
                startInfiniteScroll()
            }
        }
    }

    func beginInfiniteScrolling() {
        if !enabled {
            return
        }
        if state == .none {
            startInfiniteScroll()
        }
    }

    func endInfiniteScrolling() {
        endInfiniteScrolling(withStoppingContentOffset: false)
    }

    func endInfiniteScrolling(withStoppingContentOffset stopContentOffset: Bool) {
        if state == .loading {
            stopInfiniteScroll(withStoppingContentOffset: stopContentOffset)
        }
    }

    func changeState(_ state: LoadMoreState) {
        if self.state == state {
            return
        }
        self.state = state
        // 没处理
//        if delegate.responds(to: Selector("infinityScrollBackgroundView:didChangeState:")) {
//            delegate.infinityScrollBackgroundView(self, didChange: state)
//        }
    }

    /// 返回scrollView实际内容区域
    func adjustedHeightFromScrollViewContentSize() -> CGFloat {
        guard let scrollView = self.scrollView else { return 0.0 }
        if scrollView.contentSize.height <= 0 {
            return 0
        }
        let remainingHeight: CGFloat = bounds.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        if scrollView.contentSize.height < remainingHeight {
            return remainingHeight
        }
        return scrollView.contentSize.height
    }

    @objc
    func callInfiniteScrollActionHandler() {
        // 如果已经从父View上移除，不需要再回调了
        if self.superview == nil {
            return
        }
        handler?()
    }

    func startInfiniteScroll() {
        guard let scrollView = self.scrollView else { return }
        isHidden = false
        self.loadingView.startLoading()
        var contentInset: UIEdgeInsets = scrollView.contentInset
        contentInset.bottom += frame.height
        // We have to pad scroll view when content height is smaller than view bounds.
        // This will guarantee that view appears at the very bottom of scroll view.
        let adjustedContentHeight: CGFloat = adjustedHeightFromScrollViewContentSize()
        let extraBottomInset: CGFloat = adjustedContentHeight - scrollView.contentSize.height
        // Add empty space padding
        contentInset.bottom += extraBottomInset
        // Save extra inset
        infiniteScrollBottomContentInset = extraBottomInset
        changeState(.loading)
        setScrollViewContentInset(contentInset, animated: false, completion: { [weak self](_ finished: Bool) -> Void in
            if finished {
                self?.scrollToInfiniteIndicatorIfNeeded()
            }
        })
        // Whether should the handler execution be delayed until scroll deceleration or not
        if callInfiniteScrollActionImmediatly {
            callInfiniteScrollActionHandler()
        } else {
            perform(#selector(self.callInfiniteScrollActionHandler), with: self, afterDelay: 0.1, inModes: [.default])
        }
    }

    func stopInfiniteScroll(withStoppingContentOffset stopContentOffset: Bool) {
        guard let scrollView = self.scrollView else { return }
        self.loadingView.stopLoading()
        var contentInset: UIEdgeInsets = scrollView.contentInset
        contentInset.bottom -= frame.height
        // remove extra inset added to pad infinite scroll
        contentInset.bottom -= infiniteScrollBottomContentInset
        let offset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y)
        setScrollViewContentInset(contentInset, animated: !stopContentOffset, completion: { [weak self] (_ finished: Bool) -> Void in
            guard let `self` = self else { return }
            if stopContentOffset {
                scrollView.contentOffset = offset
            }
            if finished {
                if !self.shouldShowWhenDisabled {
                    self.isHidden = true
                }
                self.resetScrollViewContentInset(withCompletion: { (_ finished: Bool) -> Void in
                    self.changeState(.none)
                })
            }
        })
    }

    func resetScrollViewContentInset(withCompletion completion: @escaping (_ finished: Bool) -> Void) {
        UIView.animate(withDuration: 0.3, delay: 0, options: ([.allowUserInteraction, .beginFromCurrentState]), animations: { () -> Void in
            self.setScrollViewContentInset(self.originalContentInset)
        }, completion: completion)
    }

    func resetFrame() {
        guard let scrollView = self.scrollView else { return }
        let height: CGFloat = bounds.height
        let contentHeight: CGFloat = adjustedHeightFromScrollViewContentSize()
        var frame = CGRect(x: -originalContentInset.left, y: contentHeight, width: scrollView.bounds.width, height: height)
        if preserveContentInset {
            frame = CGRect(x: 0.0, y: contentHeight + originalContentInset.bottom, width: scrollView.bounds.width, height: height)
        }
        self.frame = frame
    }

    func scrollToInfiniteIndicatorIfNeeded() {
        guard let scrollView = self.scrollView else { return }
        if !scrollView.isDragging && state == .loading {
            // adjust content height for case when contentSize smaller than view bounds
            let contentHeight: CGFloat = adjustedHeightFromScrollViewContentSize()
            let height: CGFloat = frame.height
            let bottomBarHeight: CGFloat = (scrollView.contentInset.bottom - height)
            let minY: CGFloat = contentHeight - scrollView.bounds.size.height + bottomBarHeight
            let maxY: CGFloat = minY + height
            if scrollView.contentOffset.y > minY && scrollView.contentOffset.y < maxY {
                scrollView.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
            }
        }
    }

    func setScrollViewContentInset(_ contentInset: UIEdgeInsets, animated: Bool, completion: @escaping (_ finished: Bool) -> Void) {
        let updateBlock: (() -> Void) = { () -> Void in
            self.setScrollViewContentInset(contentInset)
        }
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                options: ([.allowUserInteraction, .beginFromCurrentState]),
                animations: updateBlock,
                completion: completion
            )
        } else {
            UIView.performWithoutAnimation(updateBlock)
            completion(true)
        }
    }

    func setScrollViewContentInset(_ contentInset: UIEdgeInsets) {
        let alreadyUpdating: Bool = updatingScrollViewContentInset
        // Check to prevent errors from recursive calls.
        if !alreadyUpdating {
            updatingScrollViewContentInset = true
        }
        scrollView?.contentInset = contentInset
        if !alreadyUpdating {
            updatingScrollViewContentInset = false
        }
    }
}
