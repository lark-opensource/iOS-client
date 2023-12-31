//
//  DetailAncestorTaskModule.swift
//  Todo
//
//  Created by 迟宇航 on 2022/7/18.
//

import CTFoundation
import EENavigator
import RxSwift
import RxCocoa
import LarkContainer

// nolint: magic number
final class DetailAncestorTaskModule: DetailBaseModule, HasViewModel {

    let viewModel: DetailAncestorTaskViewModel
    private lazy var rootView = DetailAncestorTaskView()
    private let disposeBag = DisposeBag()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    // 调用ViewModel层给view赋值数据
    override func setup() {
        // bind view data
        viewModel.rxViewData.bind(to: rootView).disposed(by: disposeBag)

        // bind view action
        rootView.onTapAncestorHandler = { [weak self] guid in
            self?.jumpToAncestorTask(guid: guid)
        }
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func jumpToAncestorTask(guid: String?) {
        guard let guid = guid, let viewController = context.viewController else {
            Detail.logger.info("jump to ancestor failed ,guid: \(guid ?? "")")
            return
        }
        Detail.Track.clickAncestor(with: guid)
        let detailVC = DetailViewController(
            resolver: userResolver,
            input: .edit(guid: guid, source: .ancestor, callbacks: .init())
        )
        userResolver.navigator.push(detailVC, from: viewController)
    }

}
