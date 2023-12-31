//
//  ReplyStatusComponentBinder.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class ReplyStatusComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ReplyStatusComponentViewModelContext>: ComponentBinder<C> {
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
        guard let vm = vm as? ReplyStatusComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = vm.iconSize
        props.attributedText = vm.attributeText
        props.alignIconCenter = true
        props.icon = vm.colorfulIcon
        if vm.config.replyCanTap {
            props.onViewClicked = { [weak vm] in
                vm?.replyDidTapped()
            }
        }
        _component.props = props
        style.marginTop = 4
        style.alignItems = .center
    }
}
