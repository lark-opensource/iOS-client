//
//  PinEventShareComponentBinder.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/24.
//

import Foundation
import LarkMessageBase
import LarkMessageCore
import AsyncComponent

final public class PinEventShareComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinEventShareViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = MessageBriefComponent<C>.Props()
    private lazy var _component: MessageBriefComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: MessageBriefComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = MessageBriefComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinEventShareViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.contentPreferMaxWidth = vm.contentWidth
        props.title = vm.title
        props.content = vm.displayContent
        props.setIcon = { [weak vm] view in
            view.image = vm?.icon
        }
        _component.props = props
    }
}
