//
//  MessageListEngineComponent.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/3/28.
//

import EEFlexiable
import AsyncComponent
import LarkMessageBase

final public class MessageListEngineComponentProps<C: Context>: ASComponentProps {
    public var subComponents: [ComponentWithContext<C>] = []
    // 元素上下间距
    public var componentSpacing: CGFloat?
    // 与列表容器的上间距
    public var marginTop: CGFloat?
    // 与列表容器的下间距
    public var marginBottom: CGFloat?

    init(subComponents: [ComponentWithContext<C>] = []) {
        self.subComponents = subComponents
    }
}

final public class MessageListEngineComponent<C: Context>: ASComponent<MessageListEngineComponentProps<C>, EmptyState, UIView, C> {
    public override init(props: MessageListEngineComponentProps<C>, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style)
        setupComponents(props: props)
        setSubComponents(props.subComponents)
    }

    public override func willReceiveProps(_ old: MessageListEngineComponentProps<C>, _ new: MessageListEngineComponentProps<C>) -> Bool {
        setupComponents(props: new)
        setSubComponents(new.subComponents)
        return true
    }

    private func setupComponents(props: MessageListEngineComponentProps<C>) {
        if let componentSpacing = props.componentSpacing, props.subComponents.count > 1 {
            props.subComponents[1...].forEach { component in
                component._style.marginTop = CSSValue(cgfloat: componentSpacing)
            }
        }
        if let marginTop = props.marginTop {
            props.subComponents.first?._style.marginTop = CSSValue(cgfloat: marginTop)
        }
        if let marginBottom = props.marginBottom {
            props.subComponents.last?._style.marginBottom = CSSValue(cgfloat: marginBottom)
        }
    }
}
