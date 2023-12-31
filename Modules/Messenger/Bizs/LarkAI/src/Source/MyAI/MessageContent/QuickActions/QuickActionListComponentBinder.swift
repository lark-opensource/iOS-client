//
//  QuickActionListComponentBinder.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignIcon
import UniverseDesignFont

protocol QuickActionBinderContext: QuickActionViewModelContext & QuickActionActionHanderContext {}

final class QuickActionComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: QuickActionBinderContext>: NewComponentBinder<M, D, C> {
    private var props = QuickActionListViewComponentProps(key: "quickaction_component_key")
    private lazy var _component: QuickActionListViewComponent<C> = .init(props: .init(), style: .init())
    override var component: QuickActionListViewComponent<C> { return _component }
    private let quickActionViewModel: QuickActionComponentViewModel<M, D, C>?
    private let quickActionActionHandler: QuickActionComponentActionHandler<C>?

    init(
        key: String? = nil,
        context: C? = nil,
        viewModel: QuickActionComponentViewModel<M, D, C>?,
        actionHandler: QuickActionComponentActionHandler<C>?
    ) {
        self.quickActionViewModel = viewModel
        self.quickActionActionHandler = actionHandler
        // 设置点击事件
        self.props.onTapped = { [weak actionHandler, weak viewModel] quickAction in
            guard let vm = viewModel else { return }
            actionHandler?.handleQuickActionClick(quickAction, chat: vm.metaModel.getChat(), message: vm.metaModel.message)
        }
        super.init(key: key, context: context, viewModel: viewModel, actionHandler: actionHandler)
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        _component = QuickActionListViewComponent(props: self.props, style: style)
    }

    override func syncToBinder(key: String?) {
        guard let vm = self.quickActionViewModel else {
            assertionFailure()
            return
        }
        _component.style.ui.masksToBounds = false
        _component.style.display = .flex
        switch vm.actionStatus {
        case .hidden:
            _component.style.marginTop = CSSValue(cgfloat: 0)
            props.isLoading = false
            props.quickActionList = []
        case .loading:
            // 自定义场景下拉快捷指令 loading 会造成抖动， 产品要求暂时下掉loading 
            _component.style.marginTop = CSSValue(cgfloat: 0)
            props.isLoading = false
            props.quickActionList = []
        case .shown:
            _component.style.marginTop = CSSValue(cgfloat: QuickActionListView.Cons.buttonSpacing)
            props.isLoading = false
            props.quickActionList = vm.currentQuickActions
        }
        _component.props = self.props
    }
}
