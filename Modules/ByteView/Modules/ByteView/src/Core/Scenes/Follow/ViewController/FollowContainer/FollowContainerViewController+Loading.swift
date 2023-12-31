//
//  FollowContainerViewController+Loading.swift
//  ByteView
//
//  Created by Prontera on 2020/5/6.
//

import Foundation
import RxSwift

extension FollowContainerViewController {
    func bindLoading() {
        viewModel.loadingRelay
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: ({ [weak self] (isLoading: Bool) in
                    guard let self = self else {
                        return
                    }
                    if isLoading {
                        Toast.showLoading(I18n.View_VM_Loading, in: self.view)
                    } else {
                        Toast.hideToasts(in: self.view)
                    }
                }),
                onDisposed: ({ [weak self] in
                    guard let self = self else {
                        return
                    }
                    Toast.hideToasts(in: self.view)
                }))
            .disposed(by: disposeBag)
    }
}
