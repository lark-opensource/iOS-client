//
//  Context.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/3/1.
//

import Foundation
import EEAtomic

public protocol Context: AnyObject {

}

extension Context {
    public static func provider<P: Context>(
        context: P? = nil,
        buildSubContext: @escaping (P?) -> Self?,
        children: [ComponentWithContext<Self>]
    ) -> ComponentWithSubContext<P, Self> {
        return ContextComponent<P, Self>(
            context: context,
            buildSubContext: buildSubContext,
            children: children
        )
    }
}

public final class EmptyContext: Context {
    public init() { }
}

public protocol Component: AnyObject {
    var key: String { get }
    var isLeaf: Bool { get }
    var isLayoutContainer: Bool { get }
    /// 是否使用sizeToFit计算自身大小
    var isSelfSizing: Bool { get }
    /// 是否是复合组件，即一个Component对应的UI控件不是单一节点
    var isComplex: Bool { get }
    var _style: ASComponentStyle { get set }

    func render() -> BaseVirtualNode

    func complexRender() -> [BaseVirtualNode]
}

open class ComponentWithSubContext<Ctx: Context, SubCtx: Context>: ComponentWithContext<Ctx> {
    private let semaphore = DispatchSemaphore(value: 1)
    private var _children: [ComponentWithContext<SubCtx>]
    public var children: [ComponentWithContext<SubCtx>] {
        get {
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            return self._children
        }
        set {
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            self._children = newValue
        }
    }

    init(context: Ctx? = nil, children: [ComponentWithContext<SubCtx>] = []) {
        self._children = children
        super.init(context: context)
        setSubContext()
    }

    func setSubContext() {
        let children = self.children
        children.forEach { child in
            let subContext = createSubContext()
            if child.context == nil, subContext != nil {
                child.context = subContext
            }
        }
    }

    func createSubContext() -> SubCtx? {
        return nil
    }

    override func fillComponentKey() {
        let children = self.children
        for index in 0..<children.count {
            let child = children[index]
            if child.shouldFillComponentKey() {
                child.autoKey = "\(self.key).\(index)"
            }
            child.fillComponentKey()
        }
    }
}

open class ComponentWithContext<Ctx: Context>: Component {
    // 内部自动生成的唯一Key
    internal var autoKey: String = ""
    public var key: String {
        return autoKey
    }

    public var isLeaf: Bool {
        return false
    }

    public var isLayoutContainer: Bool {
        return false
    }

    public var isSelfSizing: Bool {
        return false
    }

    public var isComplex: Bool {
        return false
    }

    public var _style: ASComponentStyle {
        get {
            return atomicExtra.value.style
        }
        set {
            atomicExtra.value.style = newValue
        }
    }

    public var context: Ctx? {
        get {
            return atomicExtra.value.context
        }
        set {
            atomicExtra.value.context = newValue
        }
    }

    struct ComponentWithContextErtra {
        var style: ASComponentStyle!
        var context: Ctx?
    }
    var atomicExtra: AtomicObject<ComponentWithContextErtra>!

    init(context: Ctx? = nil) {
        self.atomicExtra = AtomicObject(ComponentWithContextErtra(context: context))
    }

    public func render() -> BaseVirtualNode {
        assertionFailure("Must be overrided!")
        return BaseVirtualNode(tag: 0, isLayoutContainer: isLayoutContainer)
    }

    public func complexRender() -> [BaseVirtualNode] {
        return [render()]
    }

    public func getProps() -> ASComponentProps? {
        return nil
    }

    // 需要在render之前给未指定componentKey的节点赋一个key
    func fillComponentKey() {
    }

    // 是否应该自动生成componentKey
    func shouldFillComponentKey() -> Bool {
        return key.isEmpty
    }
}

public final class ContextComponent<C: Context, S: Context>: ComponentWithSubContext<C, S> {
    public var buildSubContext: ((_ context: C?) -> S?)?

    public init(
        context: C? = nil,
        buildSubContext: ((_ context: C?) -> S?)? = nil,
        children: [ComponentWithContext<S>] = []) {
        self.buildSubContext = buildSubContext
        super.init(context: context, children: children)
    }

    override func createSubContext() -> S? {
        return buildSubContext?(context)
    }

    public override func complexRender() -> [BaseVirtualNode] {
        let children = self.children
        return children.flatMap({ $0.complexRender() })
    }
}
