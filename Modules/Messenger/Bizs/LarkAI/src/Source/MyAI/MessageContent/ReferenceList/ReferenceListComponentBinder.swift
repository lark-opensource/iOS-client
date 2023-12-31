//
//  ReferenceListComponentBinder.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase

public protocol ReferenceListBinderContext: ReferenceListViewModelContext & ReferenceListActionHanderContext {}

final class ReferenceListComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ReferenceListBinderContext>: NewComponentBinder<M, D, C> {
    private let props = ReferenceListViewProps(key: "reference_list_component_key")
    private lazy var _component: ReferenceListViewComponent<C> = .init(props: .init(), style: .init())
    public override var component: ReferenceListViewComponent<C> {
        return _component
    }
    private let actionButtonViewModel: ReferenceListComponentViewModel<M, D, C>?
    private let actionButtonActionHandler: ReferenceListComponentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        viewModel: ReferenceListComponentViewModel<M, D, C>?,
        actionHandler: ReferenceListComponentActionHandler<C>?
    ) {
        self.actionButtonViewModel = viewModel
        self.actionButtonActionHandler = actionHandler
        super.init(key: key, context: context, viewModel: viewModel, actionHandler: actionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ReferenceListViewComponent<C>(props: self.props, style: ASComponentStyle(), context: context)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.actionButtonViewModel, let actionHandler = self.actionButtonActionHandler else {
            assertionFailure()
            return
        }
        self.props.needShowAllReferenceList = vm.referenceIsShowMore
        self.props.referenceList.removeAll(); self.props.referenceList.append(contentsOf: vm.referenceList.getImmutableCopy())
        self.props.showMoreDelegate = vm
        self.props.tagAEventDelegate = actionHandler
        _component.props = self.props
    }
}
