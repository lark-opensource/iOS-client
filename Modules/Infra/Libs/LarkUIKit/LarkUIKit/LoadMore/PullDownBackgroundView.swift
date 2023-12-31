//
//  PullDownBackgroundView.swift
//  LarkUIKit
//
//  Created by zhuchao on 2017/9/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol PullDownRefreshProtocol: UIView {
    var enabled: Bool { get set }
    func endRefresh()
    func beginRefresh()
    func resetFrame()
}

/// 若上层业务方在PullDownBackgroundView加载过程中也需要调整contentInset，需要实现此协议
public protocol PullDownRefreshScrollInsetCustomView: UIScrollView {
    var originalContentInset: UIEdgeInsets { get }
}

open class PullDownBackgroundView: UIView, PullDownRefreshProtocol {
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

    public var enabled: Bool = true {
        didSet {
            if enabled {
                resetFrame()
            } else {
                endInfiniteScrolling(withStoppingContentOffset: false)
            }
        }
    }

    var callInfiniteScrollActionImmediatly: Bool = true
    var updatingScrollViewContentInset: Bool = false
    var infiniteScrollBottomContentInset: CGFloat = 0.0
    let indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    var originalContentInset: UIEdgeInsets = UIEdgeInsets.zero // 初始状态的inset
    let triggerOffSet: CGFloat

    init(height: CGFloat, scrollView: UIScrollView) {
        self.triggerOffSet = 0
        self.scrollView = scrollView
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: height))
        self.originalContentInset = scrollView.contentInset
        self.setupUI()
    }

    init(height: CGFloat, scrollView: UIScrollView, triggerOffSet: CGFloat) {
        self.triggerOffSet = triggerOffSet
        self.scrollView = scrollView
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: height))
        self.originalContentInset = scrollView.contentInset
        self.setupUI()
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
            /// 若上层业务方在PullDownBackgroundView加载过程中存在调整contentInset，需要调整为View自己声明的originalContentInset（不使用PullDownBackgroundView init时的contentInset）
            if let scrollView = scrollView as? PullDownRefreshScrollInsetCustomView {
                self.scrollView?.contentInset = scrollView.originalContentInset
            } else {
                self.scrollView?.contentInset = self.originalContentInset
            }
            self.originalContentInset = .zero
        }
    }

    func setupUI() {
        self.autoresizingMask = [.flexibleWidth]
        self.isHidden = true
        indicator.color = UIColor.ud.N600
        indicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        indicator.center = CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
        indicator.hidesWhenStopped = true
        self.addSubview(indicator)
        self.resetFrame()
    }

    fileprivate func addObserver(_ view: UIView?) {
        guard let scrollView = view as? UIScrollView else {
            return
        }
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
    }

    fileprivate func removeObserver(_ view: UIView?) {
        view?.removeObserver(self, forKeyPath: "contentOffset")
    }

    // swiftlint:disable:next block_based_kvo
    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let scrollView = self.scrollView else {
            return
        }
        // self sizing 诡异事件
        if keyPath == "contentOffset" {
            if scrollView.frame.origin.y < 0 || !enabled || change == nil {
                return
            }
            if let change, let offSet = change[.newKey] as? CGPoint {
                scrollViewDidScroll(offSet)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func scrollViewDidScroll(_ contentOffset: CGPoint) {
        let actionOffset: CGFloat = -(originalContentInset.top + self.triggerOffSet)
        if contentOffset.y < actionOffset {
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
        self.state = state
    }

    @objc
    func callInfiniteScrollActionHandler() {
        handler?()
    }

    func startInfiniteScroll() {
        isHidden = false
        self.indicator.startAnimating()
        guard var contentInset = scrollView?.contentInset else { return }
        contentInset.top += frame.height
        changeState(.loading)
        setScrollViewContentInset(contentInset, animated: false, completion: { (_ finished: Bool) -> Void in
        })
        // Whether should the handler execution be delayed until scroll deceleration or not
        if callInfiniteScrollActionImmediatly {
            callInfiniteScrollActionHandler()
        } else {
            perform(#selector(self.callInfiniteScrollActionHandler), with: self, afterDelay: 0.1, inModes: [.default])
        }
    }

    public func beginRefresh() {
        self.scrollView?.setContentOffset(CGPoint(x: 0, y: -self.bounds.height), animated: false)
    }

    public func endRefresh() {
        endInfiniteScrolling(withStoppingContentOffset: false)
    }

    func stopInfiniteScroll(withStoppingContentOffset stopContentOffset: Bool) {
        self.indicator.stopAnimating()
        setScrollViewContentInset(originalContentInset, animated: false, completion: { [weak self] (_ finished: Bool) -> Void in
            guard let `self` = self else { return }
            self.changeState(.none)
        })
    }

    public func resetFrame() {
        guard let width = self.scrollView?.bounds.width else {
            return
        }
        let height = bounds.size.height
        let frame = CGRect(
            x: -originalContentInset.left,
            y: -height,
            width: width,
            height: height
        )
        self.frame = frame
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
