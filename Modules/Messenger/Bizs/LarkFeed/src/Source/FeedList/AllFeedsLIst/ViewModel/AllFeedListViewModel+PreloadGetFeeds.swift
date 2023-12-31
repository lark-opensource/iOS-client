//
//  AllFeedListViewModel+PreloadGetFeeds.swift
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

extension AllFeedListViewModel {
    /// 加载到的response，用于更新缓存的数据
    func preloadGetFeeds() {
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .preload)
        FeedPerfTrack.trackLoadFirstPageFeeds(biz: bizType, status: .start)
        dependency.getFeedCards(filterType: self.filterType,
                                cursor: nil,
                                spanID: nil,
                                count: loadConfig.refresh,
                                traceId: trace.traceId)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                guard self.checkFilterType(result.filterType, currentFilterType: self.filterType) else {
                    return
                }
                FeedPerfTrack.trackLoadFirstPageFeeds(biz: self.bizType, status: .success)
                self.handleFeedFromGetFeed(result, trace: trace)
                self.removeJunkCache(trace: trace)
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                FeedPerfTrack.trackLoadFirstPageFeeds(biz: self.bizType, status: .fail)
                self.removeJunkCache(trace: trace)
            })
            .disposed(by: disposeBag)
    }
}
