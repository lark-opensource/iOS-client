//
//  FilterSettingDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/1/5.
//

import Foundation
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface
import LarkMessengerInterface
import LarkContainer

final class FilterSettingDependencyImpl: FilterSettingDependency {
    let userResolver: UserResolver

    private let feedAPI: FeedAPI
    let addMuteGroupEnable: Bool

    public let highlight: Bool
    let showCommonlyFilters: Bool

    let showMoreSetsItem: Bool

    let feedGroupSetting: FeedGroupSetting

    let disposeBag = DisposeBag()
    private let labelViewModel: LabelMainListViewModel

    init(resolver: UserResolver,
         showCommonlyFilters: Bool,
         highlight: Bool,
         showMoreSetsItem: Bool,
         addMuteGroupEnable: Bool,
         labelVM: LabelMainListViewModel
    ) throws {
        self.userResolver = resolver
        self.highlight = highlight
        self.showCommonlyFilters = showCommonlyFilters
        self.showMoreSetsItem = showMoreSetsItem
        self.addMuteGroupEnable = addMuteGroupEnable
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.feedGroupSetting = FeedSetting(userResolver).getGroupDisplayRuleSetting().groupSetting
        self.labelViewModel = labelVM
    }

    func getLabelRules() -> [FeedMsgDisplayFilterItem] {
        let displayRules = labelViewModel.dataModule.store.getLabels().map({
            let types = FiltersModel.transformToSelectedTypes(userResolver: userResolver, $0.meta.extraData.displayRule)
            return FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: types,
                                             filterType: .tag,
                                             itemId: Int64($0.item.id),
                                             itemTitle: $0.meta.feedGroup.name)
        })
        return displayRules
    }

    func getFilters(tryLocal: Bool) -> Observable<FiltersModel> {
        return feedAPI.getFeedFilterSettings(needAll: true, tryLocal: tryLocal).map({ [userResolver]response in
            return FiltersModel.transform(userResolver: userResolver, response)
        })
    }

    func saveFeedFiltersSetting(_ filterEnable: Bool?,
                                _ commonlyUsedFilters: [FilterItemModel]?,
                                _ usedFilters: [FilterItemModel],
                                _ msgDisplaySettingMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem],
                                _ feedGroupDisplaySettingMap: [Int64: FeedMsgDisplayFilterItem]?)
    -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        // 用户分组，这里不包括 ALL
        let firstTabs = AllFeedListViewModel.getFirstTabs()
        var commonlyList: [Feed_V1_FeedFilter]?
        if let commonlyUsedFilters = commonlyUsedFilters {
            commonlyList = commonlyUsedFilters.compactMap({ item -> Feed_V1_FeedFilter? in
                guard !firstTabs.contains(item.type), item.type != .unknown else {
                    return nil
                }
                var filter = Feed_V1_FeedFilter()
                filter.filterType = item.type
                return filter
            })
        }

        let sideList = usedFilters.compactMap({ item -> Feed_V1_FeedFilter? in
            guard !firstTabs.contains(item.type), item.type != .unknown else {
                return nil
            }
            var filter = Feed_V1_FeedFilter()
            filter.filterType = item.type
            return filter
        })

        // FeedMsgDisplayFilterItem -> Feed_V1_DisplayFeedRule
        let tempMap = msgDisplaySettingMap.compactMapValues({ item -> Feed_V1_DisplayFeedRule? in
            return FiltersModel.transformToFeedRule(userResolver: userResolver, item)
        })

        // Feed_V1_FeedFilter.TypeEnum -> Int32
        var filterDisplayFeedRule: [Int32: Feed_V1_DisplayFeedRule] = [:]
        for key in tempMap.keys {
            filterDisplayFeedRule[Int32(key.rawValue)] = tempMap[key]
        }

        var feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?
        if let feedGroupMap = feedGroupDisplaySettingMap {
            feedGroupDisplayFeedRule = feedGroupMap.compactMapValues({ item -> Feed_V1_DisplayFeedRule? in
                return FiltersModel.transformToFeedRule(userResolver: userResolver, item)
            })
        }

        return feedAPI.saveFeedFiltersSetting(filterEnable, commonlyList, sideList, filterDisplayFeedRule, feedGroupDisplayFeedRule)
    }

    // 免打扰分组开关操作
    func updateFeedFilterSettings(filterEnable: Bool, showMute: Bool?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return feedAPI.updateFeedFilterSettings(filterEnable: filterEnable, showMute: showMute)
    }

    func clickFilterToggle(status: Bool) {
        FeedTracker.GroupEdit.Click.FilterToggle(status: status)
    }

    func clickMuteToggle(status: Bool) {
        FeedTracker.GroupEdit.Click.MuteToggle(status: status)
    }

    func enableDisplayRuleSetting(_ filterType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        guard Feed.Feature(userResolver).groupSettingEnable else { return false }
        return feedGroupSetting.check(feedGroupPBType: filterType)
    }
}
