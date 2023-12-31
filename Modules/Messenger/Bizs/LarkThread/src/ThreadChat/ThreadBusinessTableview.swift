//
//  ThreadBusinessTableview.swift
//  LarkThread
//
//  Created by bytedance on 2020/12/11.
//

import Foundation
import UIKit
import LarkMessageCore

/// 代理UITableView事件，需添加对应回调
struct ThreadTableViewDelegateProxy {
    var didEndDisplayingCell: ((ThreadUITableViewEvent) -> Void)?
    var willBeginDragging: (() -> Void)?
    var didEndDecelerating: (() -> Void)?
    var didEndDragging: ((Bool) -> Void)?
}

class ThreadBusinessTableview: CommonTable {
    /// 代理
    var delegateProxy = ThreadTableViewDelegateProxy()

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegateProxy.willBeginDragging?()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegateProxy.didEndDecelerating?()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.delegateProxy.didEndDragging?(decelerate)
    }
}

extension ThreadBusinessTableview: ThreadUITableView {

    var raw: UITableView {
        return self
    }

    func didEndDisplayingCell(_ callback: @escaping (ThreadUITableViewEvent) -> Void) {
        self.delegateProxy.didEndDisplayingCell = callback
    }

    func willBeginDragging(_ callback: @escaping () -> Void) {
        self.delegateProxy.willBeginDragging = callback
    }

    func didEndDecelerating(_ callback: @escaping () -> Void) {
        self.delegateProxy.didEndDecelerating = callback
    }

    func didEndDragging(_ callback: @escaping (Bool) -> Void) {
        self.delegateProxy.didEndDragging = callback
    }
}
