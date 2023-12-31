//
//  ChatPinMessageEngineCellBinder.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/28.
//

import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessageCore

final class ChatPinMessageEngineCellBinder<C: PageContext>: ComponentBinder<C> {
    private let props: ChatPinMessageEngineCellComponent<C>.Props
    private let style = ASComponentStyle()
    private var _component: ChatPinMessageEngineCellComponent<C>
    override var component: ComponentWithContext<C> {
        return _component
    }

    init(contentComponent: ComponentWithContext<C>, context: C?) {
        props = ChatPinMessageEngineCellComponent<C>.Props(contentComponent: contentComponent)
        _component = ChatPinMessageEngineCellComponent(
            props: props,
            style: style,
            context: context
        )
        super.init(key: nil, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageEngineCellViewModel<C> else {
            assertionFailure()
            return
        }
        let contentComponent = vm.contentComponent
        contentComponent._style.maxWidth = CSSValue(cgfloat: vm.contentPreferMaxWidth)
        contentComponent._style.marginLeft = CSSValue(cgfloat: vm.metaModelDependency.contentPadding)
        contentComponent._style.marginRight = CSSValue(cgfloat: vm.metaModelDependency.contentPadding)
        let contentConfig = vm.content.contentConfig

        if !(contentConfig?.threadStyleConfig?.addBorderBySelf ?? false), (contentConfig?.hasBorder ?? false) {
            contentComponent._style.cornerRadius = 10
            contentComponent._style.boxSizing = .borderBox
            contentComponent._style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
        }
        props.contentComponent = contentComponent
        props.maxCellWidth = vm.maxCellWidth
        _component.props = props
    }
}
