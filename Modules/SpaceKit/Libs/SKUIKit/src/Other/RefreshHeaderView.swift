//
//  RefreshHeaderView.swift
//  Common
//
//  Created by Da Lei on 2018/1/22.
//

import UIKit
import ESPullToRefresh
import SKFoundation

protocol RefreshHeaderViewDelegate: AnyObject {
    func refreshAnimationBegin(view: ESRefreshComponent)
    func refreshAnimationEnd(view: ESRefreshComponent)
    func progressDidChange(view: ESRefreshComponent, progress: CGFloat)
    func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState)
}

public final class RefreshHeaderView: UIView {
    public let triggerHeight: CGFloat = 80.0
    weak var delegate: RefreshHeaderViewDelegate?
}

// MARK: ESRefreshProtocol

extension RefreshHeaderView: ESRefreshProtocol {
    public func refreshAnimationBegin(view: ESRefreshComponent) {
        delegate?.refreshAnimationBegin(view: view)
    }
    public func refreshAnimationEnd(view: ESRefreshComponent) {
        delegate?.refreshAnimationEnd(view: view)
    }

    public func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        delegate?.progressDidChange(view: view, progress: progress)
    }

    public func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        delegate?.stateDidChange(view: view, state: state)
    }
}

// MARK: ESRefreshAnimatorProtocol

extension RefreshHeaderView: ESRefreshAnimatorProtocol {
    public var view: UIView { return self }
    public var insets: UIEdgeInsets {
        get {
            return self.alignmentRectInsets
        }
        set(newValue) {
            self.layoutMargins = newValue
        }
    }

    public var trigger: CGFloat {
        get {
            return triggerHeight
        }
        set(newValue) {
            DocsLogger.debug("\(newValue)")
        }
    }

    public var executeIncremental: CGFloat {
        get {
            return 80.0
        }
        set(newValue) {
            DocsLogger.debug("\(newValue)")
        }
    }

    public var state: ESRefreshViewState {
        get {
            return .pullToRefresh
        }
        set(newValue) {
            DocsLogger.debug("\(newValue)")
        }
    }
}
