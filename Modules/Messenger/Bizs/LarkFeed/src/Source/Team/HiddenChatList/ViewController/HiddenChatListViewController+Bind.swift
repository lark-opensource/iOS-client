//
//  HiddenChatListViewController+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/27.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkModel

extension HiddenChatListViewController {
    func bind() {
        viewModel.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.render()
                self.showOrRemoveEmptyView()
            }).disposed(by: disposeBag)

        viewModel.loadingStateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                guard let self = self else { return }
                self.showOrHidenLoading()
            }).disposed(by: disposeBag)

        // 监听选中态
        subscribeSelect()
    }
}
