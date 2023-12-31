//
//  DetailSourceModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/1/25.
//

import Foundation
import RxSwift
import LarkContainer
import TodoInterface
import EENavigator

/// Detail - Source - Module

// nolint: magic number
final class DetailSourceModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailSourceViewModel

    private lazy var sourceView = DetailSourceView()
    private let disposeBag = DisposeBag()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        setupView()
        bindViewData()
        viewModel.setup()
    }

    override func loadView() -> UIView {
        return sourceView
    }

    private func setupView() {
        sourceView.onLinkTap = { [weak self] url in
            guard let window = self?.context.viewController?.view.window else {
                return
            }
            self?.userResolver.navigator.open(url, from: WindowTopMostFrom(window: window))
            self?.viewModel.trackLinkTap()
        }
    }

    private func bindViewData() {
        viewModel.rxViewData.bind(to: sourceView).disposed(by: disposeBag)
    }

}
