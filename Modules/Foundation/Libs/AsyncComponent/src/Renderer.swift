//
//  Renderer.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/2/13.
//

import UIKit
import Foundation
import ThreadSafeDataStructure
import UniverseDesignTheme

private let defaultProcessQueue = DispatchQueue(label: "ASComponent.Renderer.Default", qos: .default)
private var componentToViewVTable: ThreadSafeDataStructure.SafeDictionary<Int, WeakRef<ASComponentRenderer>> = [:] + .readWriteLock
private var bucket: Int32 = 0
private var rendererCount: Int32 = 0
private var needRerenderTable: Set<Int> = Set()

/// 时间毫秒差值 + 余数 + 随机
@inline(__always)
func uuint() -> Int {
    return Int(OSAtomicIncrement32(&bucket) & Int32.max)
}

public final class ASComponentRenderer {
    weak var bindView: UIView?
    var unfairLock = os_unfair_lock_s()
    var vnode: BaseVirtualNode!
    var rootComponent: Component!
    var _renderTree: RenderTree<BaseVirtualNode>!
    var renderTree: RenderTree<BaseVirtualNode> {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _renderTree
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _renderTree = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }
    var boundingRect: CGRect = .zero
    var tag: Int
    var processQueue: DispatchQueue
    var semaphore = DispatchSemaphore(value: 1)
    // 是否使用新的applyPatchToView
    // fix: https://meego.feishu.cn/larksuite/issue/detail/13813757
    let useNewPatchView: Bool

    public convenience init<C: Context>(
        tag: Int? = nil,
        _ rootComponent: ComponentWithContext<C>,
        processQueue: DispatchQueue? = nil
    ) {
        self.init(tag: tag, rootComponent, processQueue: processQueue, useNewPatchView: false)
    }

    public init<C: Context>(
        tag: Int? = nil,
        _ rootComponent: ComponentWithContext<C>,
        processQueue: DispatchQueue? = nil,
        useNewPatchView: Bool
    ) {
        self.useNewPatchView = useNewPatchView
        self.tag = tag ?? uuint()
        self.processQueue = processQueue ?? defaultProcessQueue
        if rootComponent.key.isEmpty {
            rootComponent.autoKey = "\(self.tag)"
        }
        // 未设置key的节点，需要在render前重新设置一次
        rootComponent.fillComponentKey()
        #if DEBUG
        assertDuplicatedKey(rootComponent: rootComponent)
        #endif
        vnode = rootComponent.render()
        componentToViewVTable.removeValue(forKey: self.tag)
        self.rootComponent = rootComponent
        vnode.layout(nil)
        _renderTree = renderTreeSnapshot(buildRenderTree(vnode))
        boundingRect = renderTree.node.boundingRect
        OSAtomicIncrement32(&rendererCount)
    }

    deinit {
        OSAtomicDecrement32(&rendererCount)
        if rendererCount == 0 {
            FlexNodePoolManager.cleanMemory()
        }
    }

    public func update(
        component: Component,
        rendererNeedUpdate: (() -> Void)? = nil,
        // https://bytedance.feishu.cn/docx/BeJvdWEg9onkyMxtoGrc63gPnzU
        // 是否强制触发rendererNeedUpdate，消息卡片等场景局部刷新导致整体高度变更时，有时候会和TableView的heightForRow有时序问题，
        // 使得rendererNeedUpdate没有被触发，导致其他子组件位置不对，此处临时支持下forceUpdate，后续从框架层修复时序问题后可删除
        forceUpdate: Bool = false
    ) {
        // avoid sequence problems
        processQueue.async { [tag] in
            self._update(tag: tag, component: component, rendererNeedUpdate: rendererNeedUpdate, forceUpdate: forceUpdate)
        }
    }

    public func update<C: Context>(
        rootComponent: ComponentWithContext<C>
    ) {
        Track.start(.update_rootComponent)
        if rootComponent.key.isEmpty {
            rootComponent.autoKey = "\(tag)"
        }
        componentToViewVTable.removeValue(forKey: self.tag)
        semaphore.wait()
        Track.start(.rootComponent_render)
        rootComponent.fillComponentKey()
        #if DEBUG
        assertDuplicatedKey(rootComponent: rootComponent)
        #endif
        vnode = rootComponent.render()
        Track.end(.rootComponent_render)
        self.rootComponent = rootComponent
        Track.start(.vnode_layout)
        vnode.layout(nil)
        Track.end(.vnode_layout)
        Track.start(.renderTreeSnapshot)
        let renderTree = renderTreeSnapshot(buildRenderTree(vnode))
        boundingRect = renderTree.node.boundingRect
        Track.end(.renderTreeSnapshot)
        semaphore.signal()
        Track.end(.update_rootComponent)
        self.renderTree = renderTree
    }

    public func layout(_ size: CGSize? = nil) {
        Track.start(.layout)
        semaphore.wait()
        let renderTree = _layout(size: size)
        semaphore.signal()
        Track.end(.layout)
        self.renderTree = renderTree
    }

    public func render(_ view: UIView) {
        needRerenderTable.remove(self.tag)
        Track.start(.renderView)
        let renderTree = self.renderTree
        if renderTree.node.isHidden {
            view.isHidden = true
            Track.end(.renderView)
            return
        }
        view.isHidden = false
        // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
        // applyPatchToView(renderTree, view: view, rootView: bindView)
        if useNewPatchView {
            applyPatchToViewV2(renderTree, view: view, rootView: nil)
        } else {
            applyPatchToView(renderTree, view: view, rootView: nil)
        }
        Track.end(.renderView)
    }

    public func size() -> CGSize {
        return boundingRect.size
    }

    public func bind(to view: UIView) {
        let oldTag = view.tag

        if let traitObserver = view.traitObserver {
            traitObserver.onTraitChange = { [weak view] _ in
                guard let tag = view?.tag else {
                    return
                }
                needRerenderTable.insert(tag)
                DispatchQueue.main.async {
                    clearNeedRerender()
                }
            }
        } else {
            let traitObserver = TraitObserver(frame: .zero)
            traitObserver.onTraitChange = { [weak view] _ in
                guard let tag = view?.tag else {
                    return
                }
                needRerenderTable.insert(tag)
                DispatchQueue.main.async {
                    clearNeedRerender()
                }
            }
            view.traitObserver = traitObserver
        }

        componentToViewVTable.safeWrite { dict in
            dict[oldTag]?.ref?.bindView?.tag = 0
            dict[oldTag]?.ref?.bindView = nil
            view.tag = tag
            bindView = view
            dict[tag] = WeakRef(self)
        }
    }

    public func getView(by id: String) -> UIView? {
        guard let bindView = bindView, bindView.tag == tag else {
            return nil
        }
        if bindView.componentKey == id {
            return bindView
        }
        var stack = bindView.subviews
        while let view = stack.popLast() {
            if view.componentKey == id {
                return view
            }
            for v in view.subviews {
                stack.append(v)
            }
        }
        return nil
    }

    //根据baseKey查找views
    public func getViews(by baseKey: String) -> [UIView]? {
        guard let bindView = bindView, bindView.tag == tag else {
            return nil
        }
        var views: [UIView] = []
        if bindView.componentKey?.hasPrefix(baseKey) ?? false {
            views.append(bindView)
        }
        var stack = bindView.subviews
        while let view = stack.popLast() {
            if view.componentKey?.hasPrefix(baseKey) ?? false  {
                views.append(view)
            }
            for v in view.subviews {
                stack.append(v)
            }
        }
        return views
    }

    fileprivate func updateComponentViews() {
        guard let bindView = bindView, bindView.tag == tag else {
            return
        }
        render(bindView)
    }

    #if DEBUG
    private func assertDuplicatedKey<C: Context>(rootComponent: ComponentWithContext<C>) {
        var keys = Set<String>()
        var components = [rootComponent]
        while !components.isEmpty {
            if let sub = components.popLast() {
                if keys.contains(sub.key) {
                    assertionFailure("can not contain duplicated key: \(sub.key)")
                    break
                }
                keys.insert(sub.key)
                if let component = sub as? ComponentWithSubContext<C, C> {
                    components.append(contentsOf: component.children)
                }
            }
        }
    }
    #endif
}

private extension ASComponentRenderer {
    @inline(__always)
    func _update(
        tag: Int,
        component: Component,
        rendererNeedUpdate: (() -> Void)? = nil,
        forceUpdate: Bool
    ) {
        guard Transaction.setup else {
            return
        }
        semaphore.wait()
        if component.key == rootComponent.key {
            semaphore.signal()
            return
        }
        // 更新子节点不能调用component.fillComponentKey()，可能会与原始rootComponent中的key重复
        let newSubNode = component.render()
        findAndReplace(rootNode: vnode, subNode: newSubNode)
        let renderTree = _layout()

        var componentRenderTree: RenderTree<BaseVirtualNode>?
        if !newSubNode.isLayoutContainer {
            componentRenderTree = renderTreeSnapshot(buildRenderTree(newSubNode))
        }
        semaphore.signal()
        self.renderTree = renderTree
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let view = self.bindView else {
                rendererNeedUpdate?()
                return
            }
            if self.boundingRect == view.frame && tag == view.tag && !forceUpdate {
                Transaction(id: component.key.hashValue ^ tag) { [weak self] in
                    guard let view = self?.bindView, tag == view.tag else {
                        return
                    }
                    if let componentRenderTree = componentRenderTree,
                       let targetView = self?.getView(by: component.key) {
                        // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
                        // applyPatchToView(componentRenderTree, view: targetView, rootView: self?.bindView)
                        if self?.useNewPatchView ?? false {
                            applyPatchToViewV2(componentRenderTree, view: targetView, rootView: nil)
                        } else {
                            applyPatchToView(componentRenderTree, view: targetView, rootView: nil)
                        }
                        return
                    }
                    self?.render(view)
                }.commit()
                return
            }
            rendererNeedUpdate?()
        }
    }

    func findAndReplace(rootNode: BaseVirtualNode, subNode: BaseVirtualNode) {
        for (i, node) in rootNode.children.enumerated() {
            if node.tag == subNode.tag, let oldK = node.key, let subK = subNode.key, oldK == subK {
                var children = rootNode.children
                children[i] = subNode
                _ = rootNode.setChildren(children)
                return
            }
            findAndReplace(rootNode: node, subNode: subNode)
        }
    }

    private func analysisComponent<P: ASComponentProps, S: ASComponentState, V: UIView, C: Context>(
        _: ASComponent<P, S, V, C>
    ) {
        // TODO: 接入LCA算法，优化查找
    }

    private func _layout(size: CGSize? = nil) -> RenderTree<BaseVirtualNode> {
        vnode.layout(size)
        let renderTree = renderTreeSnapshot(buildRenderTree(vnode))
        boundingRect = renderTree.node.boundingRect
        return renderTree
    }
}

private func clearNeedRerender() {
    var renderers: [ASComponentRenderer] = componentToViewVTable.compactMap { tuple in
        if needRerenderTable.contains(tuple.key) {
            return tuple.value.ref
        }
        return nil
    }
    needRerenderTable.removeAll(keepingCapacity: true)

    for renderer in renderers {
        renderer.updateComponentViews()
    }
}

