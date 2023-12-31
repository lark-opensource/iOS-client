//
//  ShortcutsCollectionView+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import Foundation
import RxCocoa
import RxSwift
import Differentiator

// MARK: bind
extension ShortcutsCollectionView {

    func bind() {
        // 监听数据流
        viewModel.dataDriver.drive(onNext: { [weak self] update in
            guard let `self` = self else { return }
            let isDataEmpty = self.viewModel.dataSource.isEmpty
            self.loadingView.isHidden = isDataEmpty
            self.applyUpdate(update)
            FeedPerfTrack.updateShortcutFinishState(array: self.viewModel.dataSource)
        }).disposed(by: disposeBag)

        // 监听展开/收起的信号
        viewModel.expandedObservable
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] expanded in
            guard let `self` = self else { return }
            self.fullReload()
            self.loadingView.isHidden = expanded
        }).disposed(by: disposeBag)
    }
}
