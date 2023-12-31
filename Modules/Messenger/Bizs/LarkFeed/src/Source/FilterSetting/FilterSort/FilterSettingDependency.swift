//
//  FilterSettingDependency.swift
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
import LarkContainer

protocol FilterSettingDependency: UserResolverWrapper {
    var highlight: Bool { get }

    var showCommonlyFilters: Bool { get }

    // 是否展示「高级设置」选项
    var showMoreSetsItem: Bool { get }

    func getFilters(tryLocal: Bool) -> Observable<FiltersModel>

    func saveFeedFiltersSetting(_ filterEnable: Bool?,
                                _ commonlyUsedFilters: [FilterItemModel]?,
                                _ usedFilters: [FilterItemModel],
                                _ msgDisplaySettingMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem],
                                _ feedGroupDisplaySettingMap: [Int64: FeedMsgDisplayFilterItem]?)
                                -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>
    // 免打扰分组开关操作
    func updateFeedFilterSettings(filterEnable: Bool, showMute: Bool?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    func clickFilterToggle(status: Bool)

    func clickMuteToggle(status: Bool)

    var addMuteGroupEnable: Bool { get }

    // 允许展示消息分组设置的判断
    func enableDisplayRuleSetting(_ filterType: Feed_V1_FeedFilter.TypeEnum) -> Bool

    func getLabelRules() -> [FeedMsgDisplayFilterItem]
}
