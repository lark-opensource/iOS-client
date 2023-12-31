//
//  LarkEventCardBinder.swift
//  LarkCalendar
//
//  Created by heng zhu on 2019/6/17.
//

import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import AsyncComponent
import EEFlexiable

final class LarkEventCardBinder<M: CellMetaModel, D: CellMetaModelDependency, C: LarkEventCardViewModelContext>: ComponentBinder<C> {
    private lazy var _component: EventCardComponent<C> = EventCardComponent(props: .init(), style: .init(), context: nil)

    private let style = ASComponentStyle()
    private var props = EventCardComponentProps()
    private var borderGetter: (() -> Border)?

    public override var component: ComponentWithContext<C> {
        return _component
    }

    required init(key: String? = nil, context: C? = nil, borderGetter: (() -> Border)? = nil) {
        self.borderGetter = borderGetter
        super.init(key: key, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? LarkEventCardViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        _component.style.width = CSSValue(cgfloat: vm.contentWidth)
        _component.props = vm.eventCardComponentProps
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        if let border = borderGetter?() {
            style.border = border
        }

        _component = EventCardComponent(props: props, style: style, context: context)
    }
}
