//
//  FeedListViewModel+TimeCost.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/25.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import RxDataSources
import AnimatedTabBar
import RxCocoa
import ThreadSafeDataStructure
import LarkNavigation
import LarkModel
import LarkTab
import LarkMonitor

extension FeedListViewModel {
    // 打点用 for loadmore
    func recordTimeCost(_ timeCost: TimeInterval) {
        recordRelay.accept(timeCost)
    }
}
