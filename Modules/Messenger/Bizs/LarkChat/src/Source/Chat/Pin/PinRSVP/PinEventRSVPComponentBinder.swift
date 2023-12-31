//
//  PinEventRSVPComponentBinder.swift
//  LarkChat
//
//  Created by pluto on 2023/2/16.
//

import Foundation
import LarkMessageBase
import LarkMessageCore
import AsyncComponent

final public class PinEventRSVPComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinEventRSVPViewModelContext>: ComponentBinder<C> {
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
        guard let vm = vm as? PinEventRSVPViewModel<M, D, C> else {
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
