//
//  AllFeedListViewController+UIApplicationNotification.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import LarkUIKit

extension AllFeedListViewController {

    func observeApplicationNotification() {
        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.allFeedsViewModel.saveFeeds()
                self.allFeedsViewModel.saveFeedShowMuteState()
            }).disposed(by: disposeBag)
    }
}
