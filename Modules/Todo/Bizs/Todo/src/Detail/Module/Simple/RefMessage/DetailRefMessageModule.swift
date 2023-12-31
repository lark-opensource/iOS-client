//
//  DetailRefMessageModule.swift
//  Todo
//
//  Created by 张威 on 2021/2/3.
//

import EditTextView
import EENavigator
import RxSwift
import RxCocoa
import CTFoundation
import LarkContainer
import TodoInterface
import LarkUIKit

/// Detail - RefMessage - Module
/// Todo 引用的消息模块

// nolint: magic number
final class DetailRefMessageModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailRefMessageViewModel

    private(set) lazy var rootView = DetailRefMessageView()
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        bindViewData()
        bindViewAction()
        viewModel.setup()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func bindViewData() {
        viewModel.rxViewData.bind(to: rootView).disposed(by: disposeBag)
    }

    private func bindViewAction() {
        // view 被点击，展示消息详情页
        rootView.onTap = { [weak self] in
            Detail.logger.info("refMessage tapped")
            guard let self = self,
                  let vc = self.context.viewController,
                  let messageDetail = self.viewModel.messageDetail else {
                Detail.assertionFailure()
                return
            }
            var routeParams = RouteParams(from: vc)
            routeParams.openType = .push
            self.routeDependency?.showMergedMessageDetail(
                withEntity: messageDetail.entity,
                messageId: messageDetail.messageId,
                params: routeParams
            )
            Detail.tracker(.todo_im_multi_select_message_expand)
        }

        // view 被删除
        rootView.onDelete = { [weak self] in
            Detail.logger.info("refMessage deleted")
            self?.viewModel.deleteResource()
        }
    }

}
