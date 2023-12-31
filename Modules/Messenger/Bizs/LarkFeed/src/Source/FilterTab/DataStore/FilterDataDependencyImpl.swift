//
//  FilterDataDependencyImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/2.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import Swinject
import LarkAccountInterface
import LarkOpenFeed
import LarkContainer
import LarkSDKInterface

final class FilterDataDependencyImpl: FilterDataDependency {
    let userResolver: UserResolver
    let feedAPI: FeedAPI
    let feedMuteConfigService: FeedMuteConfigService
    let pushFeedFilterSettings: Observable<FiltersModel>
    let pushFeedPreview: Observable<PushFeedPreview>
    let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         feedAPI: FeedAPI,
         feedMuteConfigService: FeedMuteConfigService,
         pushFeedFilterSettings: Observable<FiltersModel>,
         pushFeedPreview: Observable<PushFeedPreview>
    ) throws {
        self.userResolver = userResolver
        self.feedAPI = feedAPI
        self.feedMuteConfigService = feedMuteConfigService
        self.pushFeedFilterSettings = pushFeedFilterSettings
        self.pushFeedPreview = pushFeedPreview
    }

    var addMuteGroupEnable: Bool {
        return feedMuteConfigService.addMuteGroupEnable()
    }

    func updateShowMute(_ showMute: Bool) {
        feedMuteConfigService.updateShowMute(showMute)
    }

    func getShowMute() -> Bool {
        return feedMuteConfigService.getShowMute()
    }

    func getFilters(tryLocal: Bool) -> Observable<FiltersModel> {
        return feedAPI.getFeedFilterSettings(needAll: false, tryLocal: tryLocal).map({ [userResolver] response in
            return FiltersModel.transform(userResolver: userResolver, response)
        })
    }

    func saveFeedRuleMd5(_ md5: String) {
        guard Feed.Feature(userResolver).groupSettingEnable else { return }
        FeedKVStorage(userId: userResolver.userID).saveFeedRuleMd5(md5)
    }

    func getFeedRuleMd5FromDisk() -> String? {
        guard Feed.Feature(userResolver).groupSettingEnable else { return nil }
        return FeedKVStorage(userId: userResolver.userID).getFeedRuleMd5()
    }
}
