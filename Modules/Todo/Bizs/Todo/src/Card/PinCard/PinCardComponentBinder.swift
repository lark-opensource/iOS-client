//
//  PinCardComponentBinder.swift
//  LarkChat
//
//  Created by 白言韬 on 2020/12/14.
//

import Foundation
import LarkMessageBase
import AsyncComponent

final class PinCardComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinCardViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = PinCardBriefComponent<C>.Props()
    private lazy var _component: PinCardBriefComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: PinCardBriefComponent<C> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = PinCardBriefComponent<C>(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinCardViewModel<M, D, C> else {
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
