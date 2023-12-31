//
//  FeedPreloaderServiceImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/5.
//

import Foundation
import LarkOpenFeed
import Swinject
import LarkContainer

public protocol FeedPreloaderService {
    func preload()
}

final class FeedPreloaderServiceImpl: FeedPreloaderService, UserResolverWrapper {
    let userResolver: UserResolver
    // ScopedProvider KeyPath看到有崩溃，换一个写法试试 https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/ba145f7eb2cb942efbc0e5894967e50e?params=%7B%22end_time%22%3A1675180800%2C%22start_time%22%3A1672502400%2C%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22ios_issue_id_version%22%3A%22v2%22%2C%22event_index%22%3A1%2C%22shortCutKey%22%3A%22over_one_month%22%7D
    var allFeedsViewModel: AllFeedListViewModel? { try? userResolver.resolve(assert: AllFeedListViewModel.self) }
    var filterDataStore: FilterDataStore? { try? userResolver.resolve(assert: FilterDataStore.self) }
    var shortcutsViewModel: ShortcutsViewModel? { try? resolver.resolve(assert: ShortcutsViewModel.self) }

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func preload() {
        // ViewModels触发预加载
        _ = self.allFeedsViewModel
        _ = self.shortcutsViewModel
        _ = self.filterDataStore
    }
}
