//
//  Renderer.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/3/23.
//

import TangramLayoutKit

private let defaultProcessQueue = DispatchQueue(label: "TangramComponent.Renderer.Default", qos: .default)
// 只在主线程操作，可不加锁；NSMapTable key需要是Objc，此处不可用
private var componentToViewVTable: Dictionary<Int, WeakRef<ComponentRenderer>> = [:]

public class ComponentRenderer {
    private var virtualTree: BaseVirtualNode
    private let processQueue: DispatchQueue
    private let semaphore = DispatchSemaphore(value: 1) // 保证update时序
    public private(set) var preferMaxLayoutWidth: CGFloat
    public private(set) var preferMaxLayoutHeight: CGFloat
    public private(set) var boundingRect: CGRect = .zero
    weak var bindView: UIView?

    private var unfairLock = os_unfair_lock_s()
    private var _renderTree: RenderTreeNode!
    private var renderTree: RenderTreeNode {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer { os_unfair_lock_unlock(&unfairLock) }
            return _renderTree
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            defer { os_unfair_lock_unlock(&unfairLock) }
            _renderTree = newValue
        }
    }

    public init(
        rootComponent: Component,
        processQueue: DispatchQueue? = nil,
        preferMaxLayoutWidth: CGFloat = .nan, // 默认不限宽高
        preferMaxLayoutHeight: CGFloat = .nan
    ) {
        self.preferMaxLayoutWidth = preferMaxLayoutWidth
        self.preferMaxLayoutHeight = preferMaxLayoutHeight
        self.processQueue = processQueue ?? defaultProcessQueue // TODO: 共用同一个Queue可能会造成任务积压，提供队列池
        // 1. ComponentTree: rootComponent

        assert(!rootComponent.isLayout, "rootComponent can only be RenderComponent")

        // 2. ComponentTree -> VirtualTree：屏蔽不同ComponentNode，不同LayoutNode之间的差异，统一为VirtualNode
        let vnode = rootComponent.render()

        virtualTree = vnode

        layout()

        _renderTree = virtualTree.prun()
    }

    public func bind(to view: UIView) {
        assert(Thread.isMainThread, "bind view to Renderer can only be on main thread!")
        // 同一View实例只能绑定到一个Renderer上
        if let oldRenderer = componentToViewVTable[view.viewIdentifier] {
            oldRenderer.ref?.unbind()
        }
        self.unbind()
        bindView = view
        componentToViewVTable[view.viewIdentifier] = WeakRef(self)

        // TODO: 刷新任务合并：当触发全量刷新时，缓存的局部刷新任务可以被丢弃
    }

    public func unbind() {
        assert(Thread.isMainThread, "unbind view to Renderer can only be on main thread!")
        // 释放上一次绑定
        if let oldView = bindView {
            componentToViewVTable[oldView.viewIdentifier] = nil
        }
        bindView = nil
    }

    // 剪枝后的VirtualTree生成ViewTree
    public func render() {
        guard let view = self.bindView else { return }
        applyPatchToView(renderTree, view: view)
    }

    /// containerW/H变更时，触发重布局：会重新渲染，不会触发diff逻辑，重新调用sizeToFit & update
    ///
    /// @params: preferMaxLayoutWidth - new preferred width or use old preferMaxLayoutWidth if nil
    /// @params: preferMaxLayoutHeight - new preferred height or use old preferMaxLayoutHeight if nil
    /// @params: invalidate - invalidate will be triggered when find no matched view or root size changed
    public func update(preferMaxLayoutWidth: CGFloat?, preferMaxLayoutHeight: CGFloat?) {
        self.semaphore.wait()
        defer { self.semaphore.signal() }

        self.preferMaxLayoutWidth = preferMaxLayoutWidth ?? self.preferMaxLayoutWidth
        self.preferMaxLayoutHeight = preferMaxLayoutHeight ?? self.preferMaxLayoutHeight
        self.mark(node: self.virtualTree, isDirty: true)
        self.layout()
        self.renderTree = self.virtualTree.prun()
        self.mark(node: self.virtualTree, isDirty: false)
    }

    /// 强制更新component及其子节点；强制触发sizeToFit和update
    ///
    /// @params: component - Component that to be updated, support rootComponent or subComponent; default rootComponent if nil
    /// @params: invalidate - invalidate will be triggered when find no matched view or root size changed
    public func updateForced(component: Component? = nil, _ invalidate: (() -> Void)? = nil) {
        serialAsync { [weak self] in
            guard let self = self else { return }
            if let component = component {
                let newSubNode = component.render()
                self.mark(node: newSubNode, isDirty: true)
                self.replace(subNode: newSubNode)
            } else {
                self.mark(node: self.virtualTree, isDirty: true)
            }
            self.layout()
            let renderTree = self.virtualTree.prun()
            self.renderTree = renderTree
            self.mark(node: self.virtualTree, isDirty: false)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let view = self.getView(by: renderTree.componentKey), view.frame.size == self.boundingRect.size {
                    applyPatchToView(renderTree, view: view)
                } else {
                    invalidate?()
                }
            }
        }
    }

    /// 替换RootComponent，重新计算布局，需要外部配合调用render()来渲染到View上
    ///
    /// @params: rootComponent - new root component
    public func update(rootComponent: Component) {
        self.semaphore.wait()
        defer { self.semaphore.signal() }

        let newSubNode = rootComponent.render()
        self.virtualTree = newSubNode
        self.mark(node: self.virtualTree, isDirty: true)
        self.layout()
        self.renderTree = self.virtualTree.prun()
        self.mark(node: self.virtualTree, isDirty: false)
    }

    /// 更新Component，会触发diff逻辑，普通更新推荐使用该方法
    ///
    /// @params: component - Component that to be updated，support rootComponent or subComponent
    /// @params: invalidate - invalidate will be triggered when find no matched view or root size changed
    public func update(component: Component, _ invalidate: (() -> Void)? = nil) {
        serialAsync { [weak self] in
            guard let self = self else { return }
            let newSubNode = component.render()
            if let old = self.replace(subNode: newSubNode) {
                self.diff(old: old, new: newSubNode)
            }
            // 重新计算Layout
            self.layout()
            // 剪枝生成RenderTree
            let renderTree = self.virtualTree.prun()
            self.renderTree = renderTree
            self.mark(node: self.virtualTree, isDirty: false)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let view = self.getView(by: renderTree.componentKey), view.frame.size == self.boundingRect.size { // 根节点size未变
                    applyPatchToView(renderTree, view: view)
                } else {
                    // 根节点尺寸变化或未找到view，兜底触发外部更新
                    invalidate?()
                }
            }
        }
    }

    public func getView(by componentKey: Int) -> UIView? {
        guard let bindView = bindView else { return nil }
        if bindView.componentKey == componentKey { return bindView }
        var queue = bindView.subviews
        while !queue.isEmpty { // 广度优先
            let view = queue.removeFirst()
            if view.componentKey == componentKey { return view }
            queue.append(contentsOf: view.subviews)
        }
        return nil
    }
}

// MARK: - Private
extension ComponentRenderer {
    @inline(__always)
    private func serialAsync(action: @escaping () -> Void) {
        let safeAction = { [weak self] in
            guard let self = self else { return }
            self.semaphore.wait()
            action()
            self.semaphore.signal()
        }
        if Thread.isMainThread {
            processQueue.async { safeAction() }
        } else {
            safeAction()
        }
    }

    @inline(__always)
    private func layout() {
        let flexTree = self.virtualTree.render()
        TLCaculateLayout(flexTree, Float(self.preferMaxLayoutWidth), Float(self.preferMaxLayoutHeight), nil)
        syncFrame(from: flexTree, to: self.virtualTree)
        self.boundingRect = self.virtualTree.boundingRect
        TLNodeDeepFree(flexTree)
    }

    @discardableResult
    private func replace(subNode: BaseVirtualNode) -> BaseVirtualNode? {
        if self.virtualTree.componentKey == subNode.componentKey {
            let old = self.virtualTree
            self.virtualTree = subNode
            return old
        }
        var queue = [self.virtualTree]
        while !queue.isEmpty {
            let parent = queue.removeFirst()
            if let index = parent.children.firstIndex(where: { $0.componentKey == subNode.componentKey }) {
                var children = parent.children
                let old = children[index]
                children[index] = subNode
                parent.setChildren(children)
                return old
            }
            queue.append(contentsOf: parent.children)
        }
        return nil
    }

    private func diff(old: BaseVirtualNode, new: BaseVirtualNode) {
        assert(old.componentKey == new.componentKey, "can not diff between different node")
        if new.equalTo(old) {
            new.updateFrame(origin: old.frame.origin, size: old.frame.size)
        } else {
            new.mark(true)
        }
        let oldMap = old.children.reduce(into: [:], { $0[$1.componentKey] = $1 })
        for child in new.children {
            if let oldChild = oldMap[child.componentKey] {
                diff(old: oldChild, new: child)
            } else {
                // 同层中old没有该节点，视为新增，则当前节点及其子节点均需置为dirty
                child.mark(true)
                var queue = child.children
                while !queue.isEmpty {
                    let cur = queue.removeFirst()
                    cur.mark(true)
                    queue.append(contentsOf: cur.children)
                }
            }
        }
    }

    /// 标记node节点及其子节点状态为isDirty(true/false)
    @inline(__always)
    private func mark(node: BaseVirtualNode, isDirty: Bool) {
        var stack = [node]
        while let child = stack.popLast() {
            child.mark(isDirty)
            stack.append(contentsOf: child.children)
        }
    }
}
