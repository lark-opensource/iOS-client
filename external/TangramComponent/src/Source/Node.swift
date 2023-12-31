//
//  Node.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/3/23.
//

import TangramLayoutKit

public protocol VirtualNodeAbility: AnyObject {
    var containerSize: CGSize { get }

    func createView(_ rect: CGRect) -> UIView
    func updateView(_ view: UIView)
    // swiftlint:disable identifier_name
    func _sizeToFit(_ size: CGSize) -> CGSize
    // swiftlint:enable identifier_name
}

open class BaseVirtualNode: RenderTreeAbility {
    private var cachedSize: CGSize?

    public private(set) var children: [BaseVirtualNode] = []

    public private(set) var isLayout: Bool = false

    public let componentKey: Int
    private(set) var reflectingTag: Int?
    // isSelfSizing决定是否需要调用sizeToFit计算大小
    public let isSelfSizing: Bool
    public let props: Props
    public let style: Style

    public var isLeaf: Bool {
        return children.isEmpty
    }

    public weak var ability: VirtualNodeAbility?

    // Props & Style是否改变
    public private(set) var isDirty: Bool = false
    // 相对父元素(如Layout节点)的位置
    public private(set) var frame: CGRect = .zero
    public var parentOrigin: CGPoint = .zero
    // 剪枝(Layout节点)后，加上父元素(Layout节点)origin的位置，对应View最终位置
    public var boundingRect: CGRect {
        return .init(origin: parentOrigin + frame.origin, size: frame.size)
    }

    public init(componentKey: Int, reflectingTag: Int? = nil, isSelfSizing: Bool, props: Props, style: Style) {
        self.componentKey = componentKey
        self.reflectingTag = reflectingTag
        self.isSelfSizing = isSelfSizing
        self.props = props.clone()
        self.style = style.clone()
    }

    @discardableResult
    public func setChildren(_ children: [BaseVirtualNode]) -> Self {
        self.children = children
        return self
    }

    public func createView() -> UIView? {
        return ability?.createView(boundingRect)
    }

    internal func draw(_ view: UIView) {
        view.frame = boundingRect
        view.componentKey = componentKey
    }

    public func updateView(_ view: UIView) {
        ability?.updateView(view)
    }

    @inline(__always)
    public func mark(_ isDirty: Bool) {
        self.isDirty = isDirty
    }

    public func updateFrame(origin: CGPoint? = nil, size: CGSize? = nil) {
        if let origin = origin {
            self.frame.origin = origin
        }
        if let size = size {
            self.frame.size = size
        }
    }

    open func equalTo(_ old: BaseVirtualNode) -> Bool {
        return props.equalTo(old.props) && style.equalTo(old.style) && isSelfSizing == old.isSelfSizing // 两次都是通过sizeToFit计算出来的大小
    }

    public func sizeToFit(_ size: CGSize) -> CGSize {
        guard let ability = ability else { return .zero }
        // containerSize & Props & Style都没变，则通过sizeToFit算出来的大小也相同，直接返回上一次计算大小
        if !isDirty, ability.containerSize == size, let cachedSize = cachedSize {
            return cachedSize
        }
        let selfSize = ability._sizeToFit(size)
        cachedSize = selfSize
        return selfSize
    }

    /// 创建FlexTree，用于计算布局
    /// @return: TLNodeRef - TLNode
    open func render() -> TLNodeRef {
        let node = TLNodeNew()!
        // sync style
        style.sync(to: node)
        // set context
        let context: UnsafeMutableRawPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        TLNodeSetContext(node, context)
        // Native的自定义Layout，需要自己算布局，其会被视为叶子节点，不能在此处同步children
        return node
    }

    /// 布局：计算frame
    /// @params: size - container size or prefer size
    /// @return: CGSize - compute size
    @discardableResult
    open func layout(_ size: CGSize) -> CGSize {
        assertionFailure("must be overrided!")
        return .zero
    }

    /// 剪枝：移除所有Layout节点
    func prun() -> RenderTreeNode {
        var renderTree = RenderTreeNode(ability: self,
                                        reflectingTag: reflectingTag,
                                        componentKey: componentKey,
                                        isDirty: isDirty)
        var children = self.children
        var idx = 0
        while idx < children.count {
            if !children[idx].isLayout {
                idx += 1
                continue
            }
            if children[idx].children.isEmpty {
                children.remove(at: idx)
            } else {
                let child = children[idx]
                child.children.forEach { $0.parentOrigin = child.boundingRect.origin }
                children.replaceSubrange(idx..<(idx + 1), with: child.children)
            }
        }
        children.forEach { child in
            renderTree.children.append(child.prun())
        }
        return renderTree
    }
}

public class RenderVirtualNode: BaseVirtualNode {
    public override var isLayout: Bool {
        false
    }

    public override func render() -> TLNodeRef {
        let node = super.render()
        // sync LayoutFunc
        if isSelfSizing {
            TLNodeSetLayoutFunc(node) { (node, width, _, height, _, _) -> TLSize in
                if let context = TLNodeGetContext(node) {
                    // 当width/height中有nan时，视为不限宽高
                    let width = width.isNaN ? CGFloat.undefined : CGFloat(width)
                    let height = height.isNaN ? CGFloat.undefined : CGFloat(height)
                    let vnode = Unmanaged<BaseVirtualNode>.fromOpaque(context).takeUnretainedValue()
                    let size = vnode.sizeToFit(.init(width: width, height: height))
                    // CGFloat在64位上为Double，此时转Float会被截断，另外为了减小误差，从第四位向上取
                    let precision: CGFloat = 10000
                    return TLSize(width: Float(ceil(size.width * precision) / precision), height: Float(ceil(size.height * precision) / precision))
                }
                return TLSize(width: 0, height: 0)
            }
        }

        // sync children
        let children: [TLNodeRef?] = self.children.map { $0.render() }
        TLNodeSetChildren(node, children, UInt32(children.count))
        return node
    }

    /// layout方法中需要处理当Render节点由子元素撑开时的大小，Render节点的具体大小将由父节点(Layout)通过Style，sizeToFit等信息共同决策
    /// Render节点的origin & size需要在父元素(Layout)中设置；根Render节点在引擎(TLCaculateLayout)中已处理
    public override func layout(_ size: CGSize) -> CGSize {
        // Render节点只会有一个Layout子节点，因此children正常为1；另外Render节点不具备layout能力，
        // 因此children的layout方法都直接传入container size即可
        let childrenSize = children.map { $0.layout(size) }
        let maxW = childrenSize.max { (lhs, rhs) -> Bool in
            return lhs.width < rhs.width
        }?.width ?? frame.width
        let maxH = childrenSize.max { (lhs, rhs) -> Bool in
            return lhs.height < rhs.height
        }?.height ?? frame.height
        return .init(width: maxW, height: maxH)
    }
}

// 不同的Layout会有不同的LayoutVirtualNode
open class LayoutVirtualNode: BaseVirtualNode {
    public override var isLayout: Bool {
        true
    }

    public init(componentKey: Int, isSelfSizing: Bool, props: Props, style: Style, ability: VirtualNodeAbility, children: [BaseVirtualNode]) {
        super.init(componentKey: componentKey, reflectingTag: nil, isSelfSizing: isSelfSizing, props: props, style: style)
        self.ability = ability
        self.setChildren(children)
    }

    /// 此处override的render方法为Native层自定义Layout的默认render实现，若业务方需要用Native(swift)自定义Layout布局
    /// 只需要override layout方法布局子元素即可，render采用默认实现即可
    /// ⚠️: 对于C++层写的Layout布局，需要视情况override render方法处理children & Props & Style等
    open override func render() -> TLNodeRef {
        let node = super.render()
        // 对于Native的自定义Layout，需要wrapper成TLNode调用layout方法
        TLNodeSetLayoutFunc(node) { (node, width, _, height, _, _) -> TLSize in
            if let context = TLNodeGetContext(node) {
                let vnode = Unmanaged<BaseVirtualNode>.fromOpaque(context).takeUnretainedValue()
                let size = vnode.layout(.init(width: width.fixTo(), height: height.fixTo()))
                return TLSize(width: Float(size.width), height: Float(size.height))
            }
            return TLSize(width: 0, height: 0)
        }
        // 对于Native的自定义Layout，应视为叶子节点处理，故此处不可设置children信息
//        let children: [TLNodeRef?] = self.children.map { $0.render() }
//        TLNodeSetChildren(node, children, UInt32(children.count))
        return node
    }
}

public func + (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func + (_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width + rhs.width, height: lhs.height + lhs.height)
}

public func - (_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

@inline(__always)
func syncFrame(from: TLNodeRef, to: BaseVirtualNode) {
    var queue = [(from, to)]
    while !queue.isEmpty {
        let (tlNode, vNode) = queue.removeFirst()
        let frame = TLNodeGetFrame(tlNode)
        // 计算出来的frame可能有nan值，设置给layer时会导致崩溃，需要做鲁棒
        vNode.updateFrame(origin: .init(x: frame.origin.x.fixTo(), y: frame.origin.y.fixTo()),
                          size: .init(width: frame.size.width.fixTo(), height: frame.size.height.fixTo()))
        var children = [(TLNodeRef, BaseVirtualNode)]()
        var count = TLNodeGetChildrenCount(tlNode)
        assert(count == vNode.children.count, "syncFrame error, children count not equal: \(count) -> \(vNode.children.count)")
        count = min(count, vNode.children.count)
        for index in 0..<count {
            if let child = TLNodeGetChild(tlNode, index) {
                children.append((child, vNode.children[index]))
            } else {
                assertionFailure("TLNodeGetChild from \(index) get nil")
            }
        }
        queue.append(contentsOf: children)
    }
}
