//
//  UrgentTipsComponentBinder.swift
//  Action
//
//  Created by KT on 2019/6/9.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class UrgentTipsComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: UrgentTipsComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = IconViewComponentProps()
    private lazy var _component: IconViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: IconViewComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = IconViewComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? UrgentTipsComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = vm.iconSize
        props.iconMarginBottom = vm.iconMarginBottom
        props.icon = Resources.urgentGrayIcon.ud.withTintColor(vm.chatComponentTheme.urgentIconColor)
        props.attributedText = vm.attributeText
        props.tapableRangeList = vm.tapableRangeList
        props.delegate = vm
        _component.props = props
        style.marginTop = 4
    }
}
