//
//  ActionButtonComponentBinder.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase
import LarkAIInfra
import LarkMessengerInterface

public protocol ActionButtonBinderContext: ActionButtonViewModelContext & ActionButtonActionHanderContext {}

final class ActionButtonComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ActionButtonBinderContext>: NewComponentBinder<M, D, C>, ActionButtonViewDelegate {
    private let props = ActionButtonViewProps(key: "action_button_component_key")
    private lazy var _component: ActionButtonViewComponent<C> = .init(props: .init(), style: .init())
    public override var component: ActionButtonViewComponent<C> {
        return _component
    }
    private let actionButtonViewModel: ActionButtonComponentViewModel<M, D, C>?
    private let actionButtonActionHandler: ActionButtonComponentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        viewModel: ActionButtonComponentViewModel<M, D, C>?,
        actionHandler: ActionButtonComponentActionHandler<C>?
    ) {
        self.actionButtonViewModel = viewModel
        self.actionButtonActionHandler = actionHandler
        super.init(key: key, context: context, viewModel: viewModel, actionHandler: actionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ActionButtonViewComponent<C>(props: self.props, style: ASComponentStyle(), context: context)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.actionButtonViewModel else {
            assertionFailure()
            return
        }
        self.props.actionButtons.removeAll(); self.props.actionButtons.append(contentsOf: vm.actionButtons.getImmutableCopy())
        self.props.delegate = self
        _component.props = self.props
    }

    public func actionButtonClick(button: MyAIChatModeConfig.ActionButton, buttonView: ActionButtonView) {
        guard let vm = self.actionButtonViewModel, let actionHandler = self.actionButtonActionHandler else {
            assertionFailure()
            return
        }
        actionHandler.actionButtonClick(button: button, chat: vm.metaModel.getChat(), message: vm.metaModel.message)
    }
}
