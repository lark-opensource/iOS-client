//
//  DetailTimeModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/1/26.
//

import CTFoundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkUIKit
import EENavigator

/// Detail - Time - Module
/// 截止时间 & 提醒时间

// nolint: magic number
final class DetailTimeModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailTimeViewModel
    private lazy var rootView = DetailDueTimeView()
    private let disposeBag = DisposeBag()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.setup()
        viewModel.rxViewData.bind(to: rootView).disposed(by: disposeBag)
        bindViewAction()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func bindViewAction() {
        rootView.contentClickHandler = { [weak self] in self?.handleContentClick() }
        rootView.emptyClickHandler = { [weak self] in self?.handleEmptyClick() }
        rootView.clearButtonHandler = { [weak self] in self?.viewModel.clearTime() }
        rootView.fullPageHandler = { [weak self] in self?.handleContentClick() }
        rootView.quickTodayHandler = { [weak self] in self?.viewModel.quickSelectToday() }
        rootView.quickTomorrowHandler = { [weak self] in self?.viewModel.quickSelectTomorrow() }
    }

    private func handleContentClick() {
        guard let containerVC = context.viewController else { return }
        switch viewModel.clickContentViewMessage() {
        case .alert(let tip):
            if let window = containerVC.view.window {
                Utils.Toast.showWarning(with: tip, on: window)
            }
        case .picker(let comps):
            let extra = TimePickerViewModel.DetailExtra(
                guid: viewModel.store.state.scene.todoId,
                rrulePermission: viewModel.store.state.permissions.rrule
            )
            let vm = TimePickerViewModel(resolver: userResolver, tuple: comps, detailExtra: extra)
            let vc = TimePickerViewController(resolver: userResolver, viewModel: vm)
            vc.saveHandler = { [weak self] comps in
                self?.viewModel.updatePickedTimeComponents(comps)
            }
            userResolver.navigator.present(
                vc,
                wrap: LkNavigationController.self,
                from: containerVC,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        case .none:
            break
        }
    }

    private func handleEmptyClick() {
        switch viewModel.emptyContentViewMessage() {
        case .alertDisable(let tip):
            if let window = self.view.window {
                Utils.Toast.showWarning(with: tip, on: window)
            }
        case .showQuick:
            viewModel.showQuickSelect()
        }
    }

    private func clearDueTime() {
        context.store.dispatch(.clearTime)
    }

}
