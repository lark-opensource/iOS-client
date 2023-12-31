//
//  PickTodoUserController.swift
//  Todo
//
//  Created by wangwanxin on 2021/11/8.
//

import Foundation
import LarkUIKit
import UniverseDesignEmpty
import LarkContainer
import UniverseDesignFont

final class PickTodoUserController: BaseViewController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let viewModel: PickTodoUserViewModel

    init(resolver: UserResolver, viewModel: PickTodoUserViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onFinishFetch = { [weak self] err in
            if let err = err {
                self?.showErrorView()
            } else {
                self?.isNavigationBarHidden = true
                self?.navigationController?.setNavigationBarHidden(true, animated: false)
                self?.jumpToRealMemberList()
            }
        }
        viewModel.setup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            viewModel.triggerCallBack()
        }
    }

}

extension PickTodoUserController {

    private func showErrorView() {
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: I18N.Todo_Task_LoadFailedTryAgainLater,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        let emptyView = UDEmptyView(config: UDEmptyConfig(
            description: description,
            type: .loadingFailure
        ))
        emptyView.backgroundColor = UIColor.ud.bgBody
        emptyView.useCenterConstraints = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

}

extension PickTodoUserController {

    private func jumpToRealMemberList() {

        let vc: UIViewController
        switch viewModel.assigneeList() {
        case.classic(let input, let dependency):
            let vm = MemberListViewModel(resolver: userResolver, input: input, dependency: dependency)
            vc = MemberListViewController(resolver: userResolver, viewModel: vm)
        case.grouped(let input, let dependency):
            let vm = GroupedAssigneeViewModel(resolver: userResolver, input: input, dependency: dependency)
            vc = GroupedAssigneeViewController(resolver: userResolver, viewModel: vm)
        }

        vc.view.frame = view.bounds
        // 为了显示child navi
        let navi = LkNavigationController(rootViewController: vc)
        navi.view.frame = view.bounds
        addChild(navi)
        view.addSubview(navi.view)
        navi.didMove(toParent: self)
    }

}
