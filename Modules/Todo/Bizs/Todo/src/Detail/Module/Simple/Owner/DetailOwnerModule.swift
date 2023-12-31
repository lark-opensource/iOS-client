//
//  DetailOwnerModule.swift
//  Todo
//
//  Created by wangwanxin on 2022/7/18.
//

import CTFoundation
import RxSwift
import RxCocoa
import EENavigator
import TodoInterface
import LarkUIKit
import LarkContainer

// nolint: magic number
final class DetailOwnerModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailOwnerViewModel

    private lazy var rootView = DetailOwnerView()
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        bindViewData()
        bindViewAction()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func bindViewData() {
        viewModel.rxViewData.bind(to: rootView).disposed(by: disposeBag)
    }
}

// MARK: - View Action

extension DetailOwnerModule {
    private func bindViewAction() {
        rootView.onEmptyHandler = { [weak self] in
            guard let self = self else { return }
            if FeatureGating(resolver: self.userResolver).boolValue(for: .multiAssignee) {
                self.showMultiOwnerPicker()
            } else {
                switch self.context.store.state.mode {
                case .taskComplete:
                    self.showSingleOwnerPicker()
               default:
                    self.showMultiOwnerPicker()
                }
            }
        }
        rootView.onSingleClearHandler = { [weak self] in
            Detail.logger.info("did single clear owner")
            self?.viewModel.removeOwner()
        }
        rootView.onSingleContentHandler = { [weak self] in
            guard let self = self else { return }
            if FeatureGating(resolver: self.userResolver).boolValue(for: .multiAssignee) {
                self.showOwnerList()
            } else {
                self.showSingleOwnerPicker()
            }
        }
        rootView.onMultiHandler = { [weak self] in
            self?.showOwnerList()
        }
        rootView.onTapSection = { [weak self] in
            self?.showSectionPicker()
        }
    }

    private func showSectionPicker() {
        Detail.logger.info("show owned section picker")
        let viewModel = DetailTaskListPickerViewModel(resolver: userResolver, scene: viewModel.scene)
        let vc = DetailTaskListPickerViewController(with: viewModel)
        vc.didSelectedHandler = { [weak self] picker in
            guard let self = self else { return }
            self.viewModel.handlePickerRes(picker)
        }
        vc.addTaskListHandler = { [weak self] name in
            guard let self = self else { return }
            self.viewModel.createNewSection(by: name)
        }
        context.viewController?.present(vc, animated: true)
    }

    private func showSingleOwnerPicker() {
        Detail.logger.info("did show single owner picker")
        guard viewModel.canPick else {
            if let window = self.view.window {
                Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
            }
            return
        }
        guard let from = context.viewController else { return }
        var routeParams = RouteParams(from: from)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        let isAtMaxLeafLayer = context.store.state.isAtMaxLeafLayer
        let noneVisibleContent = !context.store.state.richSummary.richText.hasVisibleContent()
        let disableBatchAdd = isAtMaxLeafLayer || noneVisibleContent
        routeDependency?.showOwnerPicker(
            title: I18N.Todo_TaskDetails_AddAnOwner_Button,
            chatId: viewModel.chatId,
            selectedChatterIds: viewModel.selectedAssigneeIds,
            supportbatchAdd: true,
            disableBatchAdd: disableBatchAdd,
            batchHandler: { [weak self] fromVC in
                guard let self = self else { return }
                OwnerPicker.Track.multiSelectClick(with: self.viewModel.guid, isEdit: self.viewModel.isEdit, isSubTask: false)
                if disableBatchAdd {
                    guard let window = self.view.window else { return }
                    if isAtMaxLeafLayer {
                        Utils.Toast.showWarning(with: I18N.Todo_Add5LevelsOfSubTasksAtMost_Text, on: window)
                    }
                    if noneVisibleContent {
                        Utils.Toast.showWarning(with: I18N.Todo_PleaseEnterTaskTitle_Toast, on: window)
                    }
                    return
                }
                self.showBatchOwnerPicker(fromVC)
            },
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)
                guard let self = self, let chatterId = chatterIds.first else { return }
                Detail.logger.info("selected owner, id:\(chatterId)")
                self.viewModel.addOwner(with: chatterId)
            },
            params: routeParams
        )
        OwnerPicker.Track.view(with: viewModel.guid, isSubTask: viewModel.isSubTask, isEdit: viewModel.isEdit)
    }

    private func showBatchOwnerPicker(_ fromVC: UIViewController) {
        guard let containerVC = context.viewController else { return }
        var routeParams = RouteParams(from: fromVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showChatterPicker(
            title: I18N.Todo_MultiselectMembersToAssignTasks_Title,
            chatId: viewModel.chatId,
            isAssignee: true,
            selectedChatterIds: [],
            selectedCallback: { [weak self] _, chatterIds in
                guard let self = self else { return }
                OwnerPicker.Track.confirmClick(with: self.viewModel.guid, isEdit: self.viewModel.isEdit, isSubTask: false)
                // 注意这里需要用最外层的控制去dismiss
                containerVC.dismiss(animated: true)
                self.context.bus.post(.batchAddSubtasks(ids: chatterIds))
            },
            params: routeParams
        )
    }

    private func showMultiOwnerPicker() {
        Detail.logger.info("did show multi owner picker")
        guard let fromVC = context.viewController else { return }

        guard let (chatId, selectedChatterIds) = viewModel.pickViewMessage() else {
            if let window = self.view.window {
                Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
            }
            return
        }

        var routeParams = RouteParams(from: fromVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showChatterPicker(
            title: I18N.Todo_TaskDetails_AddAnOwner_Button,
            chatId: chatId,
            isAssignee: true,
            selectedChatterIds: selectedChatterIds,
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)
                guard let self = self else { return }
                OwnerPicker.Track.finalAddClick(with: self.viewModel.guid, isEdit: self.viewModel.isEdit, isSubTask: false)
                self.viewModel.appendPickedAssignees(by: chatterIds) { [weak self] res in
                    guard case .failure(let err) = res else { return }
                    if let window = self?.view.window {
                        Utils.Toast.showError(with: err.message, on: window)
                    }
                }

                Detail.logger.info("pick multi owner, count:\(chatterIds.count)")
            },
            params: routeParams
        )
        OwnerPicker.Track.view(with: viewModel.guid, isSubTask: viewModel.isSubTask, isEdit: viewModel.isEdit)
    }

    private func showOwnerList() {
        guard let fromVC = context.viewController else { return }

        let targetVC: UIViewController
        switch viewModel.listViewMessage() {
        case let .classic(input, dependency):
            let vm = MemberListViewModel(resolver: userResolver, input: input, dependency: dependency)
            let vc = MemberListViewController(resolver: userResolver, viewModel: vm)
            vc.onNeedsExit = { [weak self, weak vc] in
                let theVC = vc?.navigationController ?? vc
                theVC?.dismiss(animated: true) { [weak self] in
                    self?.context.bus.post(.exit(reason: .quit))
                }
            }
            targetVC = vc
        case let .grouped(input, dependency):
            let vm = GroupedAssigneeViewModel(resolver: userResolver, input: input, dependency: dependency)
            let vc = GroupedAssigneeViewController(resolver: userResolver, viewModel: vm)
            vc.onNeedsExit = { [weak self, weak vc] reason in
                let theVC = vc?.navigationController ?? vc
                let completion: (() -> Void)?
                switch reason {
                case .close:
                    completion = nil
                case .removeSelf:
                    completion = { [weak self] in
                        self?.context.bus.post(.exit(reason: .quit))
                    }
                case .complete:
                    completion = { [weak self] in
                        if let window = self?.view.window {
                            Utils.Toast.showSuccess(with: I18N.Todo_Task_BotMsgTaskFinished, on: window)
                        }
                    }
                }
                theVC?.dismiss(animated: true, completion: completion)
            }
            targetVC = vc
        }

        userResolver.navigator.present(
            targetVC,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }
}
