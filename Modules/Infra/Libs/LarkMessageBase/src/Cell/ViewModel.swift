//
//  ViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import Foundation

/// 通用的ViewModel（参照了Cell、View层级相关的设计）
open class ViewModel {

    /// 包含self的父级节点
    public weak var parent: ViewModel?

    /// self包含的子级节点
    public var children: [ViewModel] = []

    public init() {
    }

    /// 添加子节点ViewModel
    ///
    /// - Parameter child: 子节点
    public func addChild(_ child: ViewModel) {
        child.removeFromParent()
        child.parent = self
        children.append(child)
    }

    /// 将当前ViewModel从父级节点移除
    public func removeFromParent() {
        guard let parent = self.parent else {
            return
        }
        self.parent = nil
        if let index = parent.children.firstIndex(where: { $0 === self }) {
            parent.children.remove(at: index)
        }
    }

    /// 视图将要出现的时候
    open func willDisplay() {
        self.children.forEach { $0.willDisplay() }
    }

    /// 视图不在显示的时候
    open func didEndDisplay() {
        self.children.forEach { $0.didEndDisplay() }
    }

    /// 被选中的时候
    open func didSelect() {
        self.children.forEach { $0.didSelect() }
    }

    /// size 发生变化，刷新所有 children vm
    /// 子类可以 override 这个方法来更新自身数据
    open func onResize() {
        self.children.forEach { $0.onResize() }
    }
}
