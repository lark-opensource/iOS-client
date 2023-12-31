//
//  DetailFollowerModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/4.
//

import Foundation
import RxSwift
import RxCocoa
import TodoInterface
import LarkUIKit
import LarkContainer
import EENavigator
import UniverseDesignActionPanel

/// Detail - Follower - Module
/// Todo 关注者模块

// nolint: magic number
final class DetailFollowerModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailFollowerViewModel

    private lazy var rootView = DetailFollowerView()
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = DetailFollowerViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.setup()
        bindViewData()
        bindViewAction()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func bindViewData() {
        viewModel.rxViewData.bind(to: rootView).disposed(by: disposeBag)
    }

    private func bindViewAction() {
        rootView.contentClickHandler = { [weak self] in
            self?.jumpToFolllowerList()
        }

        rootView.emptyClickHandler = { [weak self] in
            guard let self = self else { return }
            if self.viewModel.canAddFollow {
                self.jumpToChatterPicker()
            } else {
                if let window = self.view.window {
                    Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
                }
            }
        }
    }

    private func jumpToFolllowerList() {
        guard let fromVC = context.viewController else { return }
        Detail.logger.info("will jump to follower list")

        let (input, dependency) = viewModel.listFollowersContext()
        let vm = MemberListViewModel(resolver: userResolver, input: input, dependency: dependency)
        let vc = MemberListViewController(resolver: userResolver, viewModel: vm)
        vc.onNeedsExit = { [weak self, weak vc] in
            vc?.dismiss(animated: true) { [weak self] in
                self?.context.bus.post(.exit(reason: .unfollow))
            }
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func jumpToChatterPicker() {
        guard let containerVC = context.viewController else { return }
        Detail.logger.info("will jump to chatter picker")

        var routeParams = RouteParams(from: containerVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        let (chatId, selectChatterIds) = viewModel.pickFollowersContext()
        routeDependency?.showChatterPicker(
            title: I18N.Todo_AddFollower_Tooltip,
            chatId: chatId,
            isAssignee: false,
            selectedChatterIds: selectChatterIds,
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)

                guard let self = self else { return }
                self.viewModel.appendPickedFollowers(by: chatterIds) { [weak self] res in
                    guard case .failure(let err) = res else { return }
                    if let window = self?.view.window {
                        Utils.Toast.showError(with: err.message, on: window)
                    }
                }

                Detail.logger.info("pick followers, count:\(chatterIds.count)")
            },
            params: routeParams
        )
    }

}
