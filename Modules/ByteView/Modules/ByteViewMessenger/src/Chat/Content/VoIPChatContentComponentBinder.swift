//
//  VoIPChatContentComponentBinder.swift
//  Action
//
//  Created by Prontera on 2019/6/20.
//

import Foundation
import AsyncComponent
import LarkMessageBase

class VoIPChatContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VoIPChatContentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = RichLabelProps()
    private lazy var _component: RichLabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }
    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? VoIPChatContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        props.preferMaxLayoutWidth = vm.preferMaxLayoutWidth
        props.attributedText = vm.attributedString
        props.font = vm.labelFont
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        style.backgroundColor = .clear
        _component = RichLabelComponent(
            props: props,
            style: style,
            context: context
        )
    }
}
