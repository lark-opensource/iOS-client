//
//  VChatMeetingCardComponentBinder.swift
//  Action
//
//  Created by Prontera on 2019/6/4.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import RxSwift

class VChatMeetingCardComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VChatMeetingCardContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = VChatMeetingCardViewComponent<C>.Props()
    private lazy var _component: VChatMeetingCardViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? VChatMeetingCardViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        if props.realVM !== vm.realVM {
            props.realVM = vm.realVM
        }
        props.content = vm.content
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = VChatMeetingCardViewComponent<C>(props: props, style: style, context: context)
    }
}

class VChatMeetingCardWithBorderComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VChatMeetingCardContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = VChatMeetingCardViewComponent<C>.Props()
    private lazy var _component: VChatMeetingCardViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? VChatMeetingCardViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        if props.realVM !== vm.realVM {
            props.realVM = vm.realVM
        }
        props.content = vm.content
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        style.cornerRadius = 8
        style.boxSizing = .borderBox
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        _component = VChatMeetingCardViewComponent<C>(props: props, style: style, context: context)
    }
}
