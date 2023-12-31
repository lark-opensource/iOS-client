//
//  DetailGanttModule.swift
//  Todo
//
//  Created by wangwanxin on 2023/6/12.
//

import Foundation
import CTFoundation
import LarkContainer
import RxSwift
import RxCocoa
import UniverseDesignActionPanel
import UniverseDesignDialog

final class DetailGanttModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailGanttViewModel
    
    private lazy var rootView = DetailGanttView()
    private let disposeBag = DisposeBag()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.rxViewData.bind(to: rootView).disposed(by: disposeBag)
        rootView.onTapPreItem = { [weak self] in
            self?.clickPre()
        }
        rootView.onTapNextItem = { [weak self] in
            self?.clickNext()
        }
    }

    override func loadView() -> UIView {
        return rootView
    }
    
}

extension DetailGanttModule {

    private func clickPre() {
        guard let dependents = viewModel.dependentTodoList(.prev) else {
            return
        }
        showDependentList(dependents, .prev)
    }

    private func clickNext() {
        guard let dependents = viewModel.dependentTodoList(.next) else {
            return
        }
        showDependentList(dependents, .next)
    }

    private func showDependentList(_ dependents: [Rust.Todo], _ type: Rust.TaskDependent.TypeEnum) {
        guard !dependents.isEmpty, let fromVC = context.viewController else { return }
        Detail.Track.clickViewListDep(with: viewModel.guid ?? "", type: type)
        let viewModel = DetailDependentListViewModel(
            resolver: userResolver,
            dependents: dependents,
            type: type,
            canEdit: viewModel.canEdit
        )
        let vc = DetailDenpendentListViewController(viewModel: viewModel)
        vc.removeDependentHandler = { [weak self] guids in
            Detail.Track.clickRemoveDep(with: self?.viewModel.guid ?? "", type: type)
            self?.viewModel.removeDependents(guids, type)
        }
        vc.didAddedDependentHandler = { [weak self] in
            self?.showDependentPicker(type)
        }
        vc.clickTaskHandler = { [weak self] guid in
            self?.showTaskDetail(guid: guid)
        }
        let actionPanel = UDActionPanel(
            customViewController: vc,
            config: UDActionPanelUIConfig(originY: UIScreen.main.bounds.height * 0.5)
        )
        fromVC.present(actionPanel, animated: true)
    }

    private func showDependentPicker(_ type: Rust.TaskDependent.TypeEnum) {
        guard let fromVC = context.viewController else { return }
        Detail.Track.clickListAddDep(with: viewModel.guid ?? "", type: type, isAddFinal: false)
        let filterTaskGuids = viewModel.allDependentGuids()
        let vm = DetailDependentPickerViewModel(
            resolver: userResolver,
            filterTaskGuids: filterTaskGuids,
            type: type
        )
        let vc = DetailDependentPickerViewController(
            viewModel: vm) { [weak self] todos in
                Detail.Track.clickListAddDep(with: self?.viewModel.guid ?? "", type: type, isAddFinal: true)
                self?.viewModel.handlePickerDependents(todos, type)
            }
        fromVC.present(vc, animated: true)
    }

    private func showTaskDetail(guid: String) {
        guard let fromVC = context.viewController else { return }
        let detailVC = DetailViewController(
            resolver: viewModel.userResolver,
            input: .edit(guid: guid, source: .dependent, callbacks: .init())
        )
        userResolver.navigator.push(detailVC, from: fromVC)
    }

}
