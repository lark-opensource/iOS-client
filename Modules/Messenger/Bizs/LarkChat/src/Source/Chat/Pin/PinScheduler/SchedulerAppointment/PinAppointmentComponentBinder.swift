//
//  PinAppointmentComponentBinder.swift
//  LarkChat
//
//  Created by tuwenbo on 2023/4/10.
//

import Foundation
import LarkMessageBase
import LarkMessageCore
import AsyncComponent

final public class PinAppointmentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinAppointmentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = MessageBriefComponent<C>.Props()
    private var _component: MessageBriefComponent<C>?

    public override var component: MessageBriefComponent<C> {
        return _component ?? MessageBriefComponent<C>(props: props, style: style)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = MessageBriefComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinAppointmentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.contentPreferMaxWidth = vm.contentWidth
        props.title = vm.title
        props.content = vm.displayContent
        props.setIcon = { [weak vm] view in
            view.image = vm?.icon
        }
        _component?.props = props
    }
}
