//
//  FilterFixedDependency.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/6.
//

import Foundation
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface

protocol FilterFixedDependency {
    var filterActionHandler: FilterActionHandler { get }

    var fixedDataSource: [FilterItemModel] { get }

    var dataSource: [FilterItemModel] { get }

    var commonlyFiltersDSDriver: Driver<[FilterItemModel]> { get }

    var pushFeedFixedFilterSettings: Observable<FeedThreeColumnSettingModel>? { get }

    var pushDynamicNetStatus: Observable<PushDynamicNetStatus>? { get }

    func getThreeColumnsSettings(tryLocal: Bool) -> Observable<FeedThreeColumnSettingModel>

    func updateThreeColumnsSettings(showEnable: Bool, scene: Feed_V1_ThreeColumnsSetting.TriggerScene) -> Observable<Void>

    func getUnreadFeedsNum() -> Observable<Int>
    /// 获取团队或标签二级tab的未读数
    func getSubTabUnreadNum(type: Feed_V1_FeedFilter.TypeEnum, subId: String?) -> Int?

    /// 端上主动添加标记分组到常用分组栏
    func showFlagInCommonlyUsedFilters(_ commonlyUsedFilters: [Feed_V1_FeedFilter])

    /// 获取当前feed列表的分组类型
    func getCurrentFilterTab() -> Feed_V1_FeedFilter.TypeEnum

    /// 切换feed列表
    func changeFilterTab(_ type: Feed_V1_FeedFilter.TypeEnum)

    func localChangeCommonlyFilters(_ filters: [FilterItemModel])

    func updateFilterSelection(_ selection: FeedFilterSelection)
}
