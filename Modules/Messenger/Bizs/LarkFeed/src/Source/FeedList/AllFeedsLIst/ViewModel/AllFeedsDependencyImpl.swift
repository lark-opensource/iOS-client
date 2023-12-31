//
//  AllFeedsDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/10.
//

import Foundation
import RustPB
import LarkSDKInterface
import LarkRustClient
import LarkContainer
import SwiftProtobuf
import RunloopTools
import LarkOpenFeed
import RxRelay
import RxSwift
import RxCocoa

final class AllFeedsDependencyImpl: AllFeedsDependency {

    let feedGuideDependency: FeedGuideDependency

    private let feedAPI: FeedAPI

    let tabMuteBadgeObservable: Observable<Bool>

    private let feedMuteConfigService: FeedMuteConfigService

    init(tabMuteBadgeObservable: Observable<Bool>,
         feedMuteConfigService: FeedMuteConfigService,
         feedAPI: FeedAPI,
         feedGuideDependency: FeedGuideDependency
    ) {
        self.feedGuideDependency = feedGuideDependency
        self.tabMuteBadgeObservable = tabMuteBadgeObservable
        self.feedMuteConfigService = feedMuteConfigService
        self.feedAPI = feedAPI
    }

    /// 是否显示新引导
    func needShowNewGuide(guideKey: String) -> Bool {
        return feedGuideDependency.checkShouldShowGuide(key: guideKey)
    }

    var showMute: Bool {
        feedMuteConfigService.getShowMute()
    }

    func getAllBadge() -> Observable<Feed_V1_GetAllBadgeResponse> {
        return feedAPI.getAllBadge()
    }
}
