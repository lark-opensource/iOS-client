//
//  Node.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/1/27.
//

import UIKit
import Foundation
import EEFlexiable

let FlexNodePoolManager = ObjectPoolManager<FlexNode>(
    factory: { FlexNode() },
    prepareForReuse: {
        $0.reset()
    }
)

protocol FlexNodePool {
    func get() -> FlexNode
}

extension ObjectPool: FlexNodePool where T == FlexNode {
    @inline(__always)
    func get() -> FlexNode {
        return borrowOne(expansion: true)
    }
}

public class BaseVirtualNode {
    public var key: String?
    public let tag: Int

    private let style: ASComponentStyle?

    public var ability: ComponentVirtualNodeAbility?

    public var index: Int

    public let isLayoutContainer: Bool

    public var isSelfSizing: Bool = false

    public var isComplex: Bool = false

    public var isRoot: Bool {
        return parent == nil
    }

    private var _isHidden = false
    public internal(set) var isHidden: Bool {
        get {
            if let style = style {
                return style.display == .none
            }
            return _isHidden
        }
        set {
            if let style = style {
                style.display = newValue ? .none : .flex
            }
            _isHidden = newValue
        }
    }

    public var isLeaf: Bool {
        return children.isEmpty
    }

    var frame: CGRect = .zero
    public var parentOrigin: CGPoint = .zero
    public var boundingRect: CGRect {
        return CGRect(origin: frame.origin + parentOrigin, size: frame.size)
    }

    public weak var parent: BaseVirtualNode?

    public private(set) var children: [BaseVirtualNode] = []

    init(style: ASComponentStyle? = nil, tag: Int, index: Int = 0, isLayoutContainer: Bool) {
        self.style = style
        self.tag = tag
        self.index = index
        self.isLayoutContainer = isLayoutContainer
    }

    @discardableResult
    public func setChildren(_ children: [BaseVirtualNode]) -> Self {
        for child in self.children {
            child.parent = nil
        }
        if children.isEmpty {
            self.children = children
            return self
        }
        var idx = 0
        for child in children {
            child.parent = self
            child.index = idx
            if (child.key == nil || child.key!.isEmpty), let parentKey = self.key {
                child.key = "\(parentKey).\(idx)"
            }
            idx += 1
        }
        self.children = children
        return self
    }

    public func createView() -> UIView? {
        let view = ability?.createView(self.boundingRect)
        view?.componentKey = key
//        view?.isHidden = isHidden
        assert(!isHidden)
        return view
    }

    public func updateView(_ view: UIView) {
        assert(Thread.isMainThread, "Must in main thread.")
        if canAttach(view) {
            view.componentKey = key
            if isHidden {
                view.isHidden = true
                return
            }
            view.frame = boundingRect
            if #available(iOS 13.0, *) {
                view.traitCollection.performAsCurrent {
                    ability?.updateView(view)
                }
            } else {
                ability?.updateView(view)
            }
            view.isHidden = false
        }
    }

    public func canAttach(_ view: UIView) -> Bool {
        guard let ability = ability else {
            return false
        }
        return ability.canUpdateView(view, self)
    }

    public func layout(_ size: CGSize?) {
        if isHidden {
            return
        }
        var containerSize = size ?? CGSize(width: .CSSUndefined, height: .CSSUndefined)
        if let preferWidth = ability?.preferMaxLayoutWidth {
            containerSize.width = preferWidth
        }
        if let preferHeight = ability?.preferMaxLayoutHeight {
            containerSize.height = preferHeight
        }
        let pool = FlexNodePoolManager.borrowPool()
        if let flexNode = createFlexNode(pool) {
            flexNode.calculateLayout(with: containerSize)
            travelAndSyncFrame(flexNode)
        }
        FlexNodePoolManager.returnPool(pool)
    }

    @inline(__always)
    private func travelAndSyncFrame(_ flexNode: FlexNode) {
        var stack = [(self, flexNode)]
        while let last = stack.popLast() {
            last.0.frame = last.1.frame
            let count = last.1.subNodes.count
            var fnodeIdx = 0
            for child in last.0.children where !child.isHidden && fnodeIdx < count {
                if let node = last.1.subNodes[fnodeIdx] as? FlexNode {
                    stack.append((child, node))
                    fnodeIdx += 1
                } else {
                    assert(false, "SubNode cannot convert to FlexNode")
                }
            }
        }
    }

    public func render(_ view: UIView) {
        assertionFailure("Overrided.")
    }

    /// 当node可以绑定到一个view时触发，发生在addSubview之后
    public func didMount(_ view: UIView) {

    }

    public func free() {

    }

    public func merge(_ node: BaseVirtualNode) {
        assertionFailure("Overrided.")
    }

    public func equalTo(_ node: BaseVirtualNode) -> Bool {
        if let key1 = key, let key2 = node.key, key1 != key2 {
            return false
        }

        return tag == node.tag
            && index == node.index
    }

    public func clone() -> BaseVirtualNode {
        let copy = BaseVirtualNode(tag: tag, index: index, isLayoutContainer: isLayoutContainer)
        copy.parentOrigin = parentOrigin
        copy.frame = frame
        copy.isHidden = isHidden
        copy.key = key
        copy.isComplex = isComplex
        copy.isSelfSizing = isSelfSizing
        copy.ability = ability
        return copy
    }

    func createFlexNode(_ pool: FlexNodePool) -> FlexNode? {
        if isHidden {
            return nil
        }
//        let flexNode = pool.get()
        let flexNode = FlexNode()
        style?.applyToFlexStyle(flexNode.flexStyle)
        flexNode.key = key
        flexNode.isSelfSizing = isSelfSizing
        if isLeaf, isSelfSizing, ability != nil {
            flexNode.setMeasureFunc { [weak self] (w, h) -> CGSize in
                guard let delegate = self?.ability else {
                    assertionFailure("Delegate has been dealloced.")
                    return .zero
                }
                return delegate.sizeToFit(CGSize(width: w, height: h))
            }
            flexNode.markDirty()
        }
        let subFlexNodes = children.compactMap({ $0.createFlexNode(pool) })
        if !subFlexNodes.isEmpty {
            flexNode.setSubFlexNodes(subFlexNodes)
        }
        return flexNode
    }
}

final class RenderVirtualNode: BaseVirtualNode {
    public init(style: ASComponentStyle? = nil, tag: Int, index: Int = 0) {
        super.init(style: style, tag: tag, index: index, isLayoutContainer: false)
    }

    public override func didMount(_ view: UIView) {
        self.ability?.componentDidMount()
    }

    public override func render(_ view: UIView) {
        if isHidden {
            view.isHidden = true
            return
        }
        view.isHidden = false
        // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
        // applyPatchToView(buildRenderTree(self), view: view, rootView: view.asRootBindView)
        applyPatchToView(buildRenderTree(self), view: view, rootView: nil)
    }

    public override func merge(_ node: BaseVirtualNode) {

    }
}

final class LayoutVirtualNode: BaseVirtualNode {
    public override var isSelfSizing: Bool {
        get {
            return false
        }
        // swiftlint:disable:next unused_setter_value
        set {

        }
    }

    public init(style: ASComponentStyle? = nil, tag: Int, index: Int = 0) {
        super.init(style: style, tag: tag, index: index, isLayoutContainer: true)
    }

    public override func createView() -> UIView? {
        return nil
    }

    public override func updateView(_ view: UIView) {

    }

    public override func render(_ view: UIView) {

    }

    public override func merge(_ node: BaseVirtualNode) {

    }
}
