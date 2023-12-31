//
//  Component.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/3/23.
//

import Foundation
import UIKit

open class Component {
    public private(set) var componentKey: Int = 0
    public private(set) var containerSize: CGSize = .zero

    // 是否能计算自己的大小
    open var isSelfSizing: Bool { false }

    // 是否是LayoutComponent
    open var isLayout: Bool { false }

    private var rwlock = pthread_rwlock_t()
    private var _children: [Component] = []
    public private(set) var children: [Component] {
        get {
            pthread_rwlock_rdlock(&rwlock)
            defer { pthread_rwlock_unlock(&rwlock) }
            return _children
        }
        set {
            pthread_rwlock_wrlock(&rwlock)
            defer { pthread_rwlock_unlock(&rwlock) }
            _children = newValue
        }
    }

    public init() {
        // TODO: 1. componentKey需要支持通过Props指定; 2. patch时优先找key一致，再找同类型的
        componentKey = ObjectIdentifier(self).hashValue
        pthread_rwlock_init(&rwlock, nil)
    }

    // swiftlint:disable identifier_name
    final public func _sizeToFit(_ size: CGSize) -> CGSize {
        containerSize = size
        return sizeToFit(size)
    }
    // swiftlint:enable identifier_name

    open func sizeToFit(_ size: CGSize) -> CGSize {
        .zero
    }

    open func setChildren(_ children: [Component]) {
        self.children = children
    }

    // 生成VirtualTree
    open func render() -> BaseVirtualNode {
        assertionFailure("must be overrided")
        return BaseVirtualNode(componentKey: 0, reflectingTag: nil, isSelfSizing: isSelfSizing, props: EmptyProps(), style: LayoutComponentStyle())
    }
}

// 泛型影响，提供一个不带泛型的基类
open class BaseRenderComponent: Component {
    public override var isLayout: Bool {
        false
    }
    public let style: RenderComponentStyle

    public init(style: RenderComponentStyle) {
        self.style = style
    }
}

open class RenderComponent<P: Props, U: UIView, C: Context>: BaseRenderComponent {
    public let context: C?
    // props可能为class或struct，为struct时，需要为var外部才能修改
    open var props: P

    private let reflectingTag: Int

    public init(
        layoutComponent: BaseLayoutComponent? = nil,
        props: P,
        style: RenderComponentStyle = RenderComponentStyle(),
        context: C? = nil
    ) {
        self.props = props
        self.context = context
        self.reflectingTag = ObjectIdentifier(U.self).hashValue
        super.init(style: style)
        if let child = layoutComponent {
            setChildren([child])
        }
    }

    public func setLayout(_ layout: BaseLayoutComponent?) {
        if let layout = layout {
            setChildren([layout])
        }
    }

    open override func setChildren(_ children: [Component]) {
        assert(children.count <= 1, "RenderComponent cannot contain more than 1 child, prefer to use LayoutComponent")
        #if DEBUG
        if let child = children.first {
            assert(child is BaseLayoutComponent, "RenderComponent cannot contain a RenderComponent as child")
        }
        #endif
        super.setChildren(children)
    }

    open func create(_ rect: CGRect) -> U {
        return U(frame: rect)
    }

    open func update(_ view: U) {
        style.applyToView(view)
    }

    open override func render() -> BaseVirtualNode {
        let root = RenderVirtualNode(componentKey: componentKey, reflectingTag: reflectingTag, isSelfSizing: isSelfSizing, props: props, style: style)
        root.ability = self
        if let layout = children.first {
            root.setChildren([layout.render()])
        }
        return root
    }
}

extension RenderComponent: VirtualNodeAbility {
    public func createView(_ rect: CGRect) -> UIView {
        return create(rect)
    }

    public func updateView(_ view: UIView) {
        guard let u = view as? U else { return }
        update(u)
    }
}

// 泛型影响，需要有个不带泛型的Layout基类
open class BaseLayoutComponent: Component {
}

open class LayoutComponent<P: Props, C: Context>: BaseLayoutComponent {
    public override var isLayout: Bool {
        true
    }

    public let context: C?
    // props可能为class或struct，为struct时，需要为var外部才能修改
    public var props: P
    public var style: LayoutComponentStyle

    public init(children: [Component],
                props: P,
                style: LayoutComponentStyle = LayoutComponentStyle(),
                context: C? = nil) {
        self.props = props
        self.style = style
        self.context = context
        super.init()
        setChildren(children)
    }
}

extension LayoutComponent: VirtualNodeAbility {
    public func createView(_ rect: CGRect) -> UIView {
        assertionFailure("LayoutComponent cannot createView")
        return UIView(frame: .zero)
    }

    public func updateView(_ view: UIView) {
        assertionFailure("LayoutComponent cannot updateView")
    }
}
