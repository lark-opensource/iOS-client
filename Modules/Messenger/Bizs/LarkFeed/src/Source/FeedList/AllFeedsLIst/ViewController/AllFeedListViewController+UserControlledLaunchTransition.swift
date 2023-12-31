//
//  AllFeedListViewController+UserControlledLaunchTransition.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import LarkUIKit
import RxRelay
import RxSwift
import LarkPerf

extension AllFeedListViewController {
    /// 监听首屏渲染完成
    func observeFirstRendered() {
        var localDispose = DisposeBag()
        allFeedsViewModel.feedsUpdated
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                if !self.allFeedsViewModel.allItems().isEmpty {
                    self.allFeedsViewModel.firstScreenRenderedFinish.accept(true)
                    FeedPerfTrack.trackFirstScreenDataReady()
                    localDispose = DisposeBag()
                    self.sendFeedListState(state: .firstLoad)
                }
            }).disposed(by: localDispose)
    }

    // 启动页消失 判断Feed是否展示 上报Slardar
    func trackLaunchTransition() {
        var localDispose = DisposeBag()
        NotificationCenter.default.rx.notification(.launchTransitionDidDismiss)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notification) in
                guard let self = self else { return }
                guard (notification.userInfo?["show"] as? Bool) == true else { return }
                let feedsCount = self.allFeedsViewModel.allItems().count
                FeedSlardarTrack.trackFeedTransitionDisappear(feedsCount)
                FeedContext.log.info("feedlog/launchTransitionDidDismiss. feedsCount: \(feedsCount)")
                localDispose = DisposeBag()
            }).disposed(by: localDispose)
    }
}
