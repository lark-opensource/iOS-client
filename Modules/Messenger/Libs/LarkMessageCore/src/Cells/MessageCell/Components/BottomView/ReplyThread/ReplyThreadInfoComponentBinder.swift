//
//  ReplyThreadInfoComponentBinder.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/4/25.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class ReplyThreadInfoComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = ReplyThreadInfoComponent<C>.Props()
    private lazy var _component: ReplyThreadInfoComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ReplyThreadInfoComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ReplyThreadInfoComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ReplyThreadInfoComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.chatterModels = vm.chatterModels
        props.attributedText = vm.attributedText
        props.onViewClicked = { [weak vm] in
            vm?.replyDidTapped()
        }
        _component.props = props
    }
}
