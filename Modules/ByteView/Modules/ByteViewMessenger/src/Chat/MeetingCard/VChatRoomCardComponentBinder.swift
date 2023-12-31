//
//  VChatRoomCardComponentBinder.swift
//  LarkByteView
//
//  Created by Prontera on 2020/3/15.
//

import Foundation
import AsyncComponent
import RichLabel
import LarkMessageBase

final class VChatRoomCardComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VChatRoomCardViewModelContext>: ComponentBinder<C> {
    private var props = UILabelComponentProps()
    private var style = ASComponentStyle()
    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        style.backgroundColor = .clear
        props.textColor = UIColor.ud.textPlaceholder
        props.font = UIFont.systemFont(ofSize: 16)
        props.numberOfLines = 0
        _component = UILabelComponent<C>(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? VChatRoomCardViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.text = vm.text
        _component.props = props
    }
}
