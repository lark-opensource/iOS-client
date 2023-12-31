//
//  MergeForwardMessageEngineCellComponent.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/4/3.
//

import EEFlexiable
import AsyncComponent

extension ForwardMessageEngineCellComponent {
    public final class Props: ASComponentProps {
        public var contentComponent: ComponentWithContext<C>
        public var maxCellWidth: CGFloat = UIScreen.main.bounds.width

        public init(contentComponent: ComponentWithContext<C>) {
            self.contentComponent = contentComponent
        }
    }
}

public final class ForwardMessageEngineCellComponent<C: Context>: ASComponent<ForwardMessageEngineCellComponent<C>.Props, EmptyState, UIView, C> {
    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([props.contentComponent])
    }

    public override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: props.maxCellWidth)
        return super.render()
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        setSubComponents([new.contentComponent])
        return true
    }
}
