//
//  Component.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/1/26.
//

import UIKit
import Foundation
import EEAtomic

public protocol ComponentVirtualNodeAbility: AnyObject {
    var preferMaxLayoutWidth: CGFloat? { get set }
    var preferMaxLayoutHeight: CGFloat? { get set }
    func createView(_ rect: CGRect) -> UIView
    func updateView(_ view: UIView)
    func canUpdateView(_ view: UIView, _ node: BaseVirtualNode) -> Bool
    func sizeToFit(_ size: CGSize) -> CGSize
    func componentDidMount()
    func componentUnmount()
}

open class ASComponent<P: ASComponentPropsProtocol, S: ASComponentState, U: UIView, C: Context>: ComponentWithSubContext<C, C> {
    private var viewIdentify: ObjectIdentifier

    public override var key: String {
        return props.key ?? autoKey
    }

    open override var isLeaf: Bool {
        return children.isEmpty
    }

    open override var isSelfSizing: Bool {
        return false
    }

    open override var isComplex: Bool {
        return false
    }

    open override var isLayoutContainer: Bool {
        return false
    }

    private let atomicProps: AtomicObject<P>
    // public properties
    public var props: P {
        get {
            return atomicProps.value
        }
        set {
            if willReceiveProps(atomicProps.value, newValue) {
                atomicProps.value = newValue
            }
        }
    }
    public var state: S = .nil
    public var preferMaxLayoutWidth: CGFloat?
    public var preferMaxLayoutHeight: CGFloat?

    public var style: ASComponentStyle {
        return _style
    }

    public init(props: P, style: ASComponentStyle, context: C? = nil) {
        self.atomicProps = AtomicObject(props)
        self.viewIdentify = ObjectIdentifier(U.self)
        super.init(context: context, children: [])
        self.atomicExtra.value.style = style
    }

    public func setState(_ newState: S) {
        self.state = newState
    }

    open func willReceiveProps(_ old: P, _ new: P) -> Bool {
        return true
    }

    open func create(_ rect: CGRect) -> U {
        return U(frame: rect)
    }

    open func update(view: U) {
        _style.applyToView(view)
    }

    open func canUpdateView(_ view: UIView, _ node: BaseVirtualNode) -> Bool {
        return viewIdentify == view.reflectingTag || view is U
    }

    @discardableResult
    public func setSubComponents(_ components: [ComponentWithContext<C>] = []) -> Self {
        children = components
        setSubContext()
        return self
    }

    override func createSubContext() -> C? {
        return self.context
    }

    open func sizeToFit(_ size: CGSize) -> CGSize {
        return .zero
    }

    open override func render() -> BaseVirtualNode {
        let node = RenderVirtualNode(style: _style.clone(), tag: viewIdentify.hashValue)
        node.key = self.key
        let children = self.children
        node.setChildren(children.flatMap({ $0.complexRender() }))
        node.isSelfSizing = isSelfSizing
        node.isComplex = isComplex
        node.ability = self
        return node
    }

    override func shouldFillComponentKey() -> Bool {
        return props.key == nil
    }

    public override func getProps() -> ASComponentProps? {
        return props as? ASComponentProps
    }
}

extension ASComponent: ComponentVirtualNodeAbility {
    public func componentDidMount() {

    }

    public func componentUnmount() {

    }

    public func createView(_ rect: CGRect) -> UIView {
        return create(rect)
    }

    public func updateView(_ view: UIView) {
        guard let view = view as? U else {
            return
        }
        update(view: view)
    }
}

open class ASLayoutComponent<C: Context>: ComponentWithSubContext<C, C> {
    // 外部自定义Key
    private var customKey: String = ""
    public override var key: String {
        return !customKey.isEmpty ? customKey : autoKey
    }

    public override var isLeaf: Bool {
        return false
    }
    public override var isSelfSizing: Bool {
        return false
    }
    public override var isComplex: Bool {
        return false
    }
    public override var isLayoutContainer: Bool {
        return true
    }

    public var preferMaxLayoutWidth: CGFloat?

    public var preferMaxLayoutHeight: CGFloat?

    public var style: ASComponentStyle {
        return _style
    }

    public init(key: String = "",
                style: ASComponentStyle,
                context: C? = nil,
                _ subComponents: [ComponentWithContext<C>]) {
        super.init(context: context, children: subComponents)
        self.customKey = key
        self.atomicExtra.value.style = style
        setSubComponents(subComponents)
    }

    public func setSubComponents(_ components: [ComponentWithContext<C>]) {
        children = components
        setSubContext()
    }

    override func createSubContext() -> C? {
        return self.context
    }

    public override func render() -> BaseVirtualNode {
        let node = LayoutVirtualNode(style: _style.clone(), tag: ObjectIdentifier(type(of: self)).hashValue)
        node.key = key
        let children = self.children
        node.setChildren(children.flatMap({ $0.complexRender() }))
        node.isComplex = false
        node.isSelfSizing = false
        return node
    }

    override func shouldFillComponentKey() -> Bool {
        // 外部自定义Key为空时，内部自动生成
        return customKey.isEmpty
    }
}

extension ASLayoutComponent: ComponentVirtualNodeAbility {
    public func componentDidMount() {

    }

    public func componentUnmount() {

    }

    public func sizeToFit(_ size: CGSize) -> CGSize {
        return .zero
    }

    public func canUpdateView(_ view: UIView, _ node: BaseVirtualNode) -> Bool {
        return false
    }

    public func createView(_ rect: CGRect) -> UIView {
        assertionFailure("Can not call this method.")
        return UIView(frame: .zero)
    }

    public func updateView(_ view: UIView) {

    }
}
