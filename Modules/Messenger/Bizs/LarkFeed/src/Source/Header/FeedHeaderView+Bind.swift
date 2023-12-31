//
//  FeedHeaderView+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/6.
//
import Foundation
import LarkContainer
import LarkOpenFeed

extension FeedHeaderView {

    // MARK: 创建header里的viewModels
    func bindViewModels(context: UserResolver) {
        self.viewModels = FeedHeaderFactory.allViewModel(context: context)
        if self.oldWidth != 0 {
            // 补充刷新宽度逻辑 for UG banner
            self.refreshSubViewsWidth(true)
        }
        self.binds()
    }

    /// bind
    private func binds() {
        viewModels.forEach { viewModel in
            // 构造/释放各个view
            viewModel.displayDriver.distinctUntilChanged().drive(onNext: { [weak self] display in
                guard let `self` = self else { return }
                self.setupViews(display: display, viewModel: viewModel)
            }).disposed(by: disposeBag)

            // 获取各个view高度
            viewModel.updateHeightDriver.distinctUntilChanged().drive(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.fireViewHeight(viewModel: viewModel)
            }).disposed(by: disposeBag)
        }
    }
}
