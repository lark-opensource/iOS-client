//
//  ChatPinMessageEngineCellComponent.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/28.
//

import EEFlexiable
import AsyncComponent

final class ChatPinMessageEngineCellComponent<C: Context>: ASComponent<ChatPinMessageEngineCellComponent<C>.Props, EmptyState, UIView, C> {

    final class Props: ASComponentProps {
        var contentComponent: ComponentWithContext<C>
        var maxCellWidth: CGFloat = UIScreen.main.bounds.width

        init(contentComponent: ComponentWithContext<C>) {
            self.contentComponent = contentComponent
        }
    }

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([props.contentComponent])
    }

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: props.maxCellWidth)
        return super.render()
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        setSubComponents([new.contentComponent])
        return true
    }
}
