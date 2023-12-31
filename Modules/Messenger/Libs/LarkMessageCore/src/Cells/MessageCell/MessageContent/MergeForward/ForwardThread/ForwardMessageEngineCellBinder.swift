//
//  ForwardMessageEngineCellBinder.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/4/3.
//

import EEFlexiable
import AsyncComponent
import LarkMessageBase

final public class ForwardMessageEngineCellBinder<C: PageContext>: ComponentBinder<C> {
    private let props: ForwardMessageEngineCellComponent<C>.Props
    private let style = ASComponentStyle()
    private var _component: ForwardMessageEngineCellComponent<C>
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public init(key: String? = nil, context: C? = nil, contentComponent: ComponentWithContext<C>) {
        props = ForwardMessageEngineCellComponent<C>.Props(contentComponent: contentComponent)
        _component = ForwardMessageEngineCellComponent(
            props: props,
            style: style,
            context: context
        )
        super.init(key: key, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageEngineCellViewModel<C> else {
            assertionFailure()
            return
        }
        let contentComponent = vm.contentComponent
        contentComponent._style.maxWidth = CSSValue(cgfloat: vm.contentPreferMaxWidth)
        contentComponent._style.marginLeft = CSSValue(cgfloat: vm.metaModelDependency.contentPadding)
        contentComponent._style.marginRight = CSSValue(cgfloat: vm.metaModelDependency.contentPadding)
        let contentConfig = vm.content.contentConfig
        // 话题转发场景都为卡片样式
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
