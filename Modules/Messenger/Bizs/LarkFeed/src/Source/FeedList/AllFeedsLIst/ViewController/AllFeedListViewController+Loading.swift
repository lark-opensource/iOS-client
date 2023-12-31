//
//  AllFeedListViewController+Loading.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import RxSwift

/// 冷启动时，过渡图消失，但Feed数据未拉回来，需要显示Loading
extension AllFeedListViewController {
    func observeLoading() {
        var localDispose = DisposeBag()
        // 过渡图消失，检查是否显示loading
        NotificationCenter.default.rx.notification(.launchTransitionDidDismiss)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showOrHidenLoading()
                FeedContext.log.info("feedlog/loading. transition dismiss, shouldShowLoading = \(self.allFeedsViewModel.shouldShowLoading)")
            })
            .disposed(by: localDispose)

        // Feeds刷新，检查是否取消loading
        allFeedsViewModel.feedsUpdated
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showOrHidenLoading()
                FeedContext.log.info("feedlog/loading. shouldShowLoading = \(self.allFeedsViewModel.shouldShowLoading)")
                // 如果不再显示，则取消监听
                if !self.allFeedsViewModel.shouldShowLoading { localDispose = DisposeBag() }
            })
            .disposed(by: localDispose)
    }

    private func showOrHidenLoading() {
        self.loadingPlaceholderView.isHidden = !self.allFeedsViewModel.shouldShowLoading
    }
}
