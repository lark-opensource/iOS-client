//
//  TCPreviewContainerComponentBinder.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2022/6/29.
//

import Foundation
import LarkMessageBase
import AsyncComponent

final class TCPreviewContainerComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: TCPreviewContainerContext & PageContext>: NewComponentBinder<M, D, C> {
    private var props = TCPreviewContainerComponent<C>.Props()
    private lazy var _component: TCPreviewContainerComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private let style = ASComponentStyle()
    private let tcPreviewViewModel: TCPreviewContainerComponentViewModel<M, D, C>?

    override var component: TCPreviewContainerComponent<C> {
        return _component
    }

    init(
        key: String? = nil,
        context: C? = nil,
        tcPreviewViewModel: TCPreviewContainerComponentViewModel<M, D, C>?,
        actionHandler: ComponentActionHandler<C>?
    ) {
        self.tcPreviewViewModel = tcPreviewViewModel
        super.init(key: key, context: context, viewModel: tcPreviewViewModel, actionHandler: actionHandler)
    }

    override func syncToBinder(key: String?) {
        guard let vm = self.tcPreviewViewModel else {
            assertionFailure()
            return
        }
        let margin = vm.margin
        style.marginTop = margin
        style.marginLeft = margin
        style.marginRight = margin
        _component._style = style

        props.subComponents = vm.subComponents
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = TCPreviewContainerComponent(props: props, style: style, context: context)
    }
}
