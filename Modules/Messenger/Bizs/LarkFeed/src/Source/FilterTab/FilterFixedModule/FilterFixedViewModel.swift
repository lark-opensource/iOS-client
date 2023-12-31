//
//  FilterFixedViewModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/19.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB
import RunloopTools
import LarkSDKInterface
import LarkOpenFeed

struct FilterSubSelectedTab {
    let type: Feed_V1_FeedFilter.TypeEnum
    let tabId: String
}

final class FilterFixedViewModel {
    let multiLevelTabList: [Feed_V1_FeedFilter.TypeEnum] = [.team, .tag]
    var subSelectedTab: FilterSubSelectedTab?

    let dependency: FilterFixedDependency
    let disposeBag = DisposeBag()

    // 处理固定分组栏 show or hide
    var filterShowRelay = BehaviorRelay<Bool>(value: false)
    var filterShowDriver: Driver<Bool> {
        return filterShowRelay.asDriver()
    }

    // 服务端固定分组显隐状态信号
    var filterSettingShowRelay = BehaviorRelay<Bool>(value: false)
    var filterSettingShowDriver: Driver<Bool> {
        return filterSettingShowRelay.asDriver()
    }

    var netStatus: Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent
    var defaultShowFilter: Bool? // 仅赋值一次
    var firstTriggerGuide: Bool = true
    var localTrigger: Bool = false
    var filterSetting: FeedThreeColumnSettingModel?
    var mainViewAppeared: Bool = false
    let delay: CGFloat = 0.3

    init(dependency: FilterFixedDependency) {
        self.dependency = dependency

        RunloopDispatcher.shared.addTask(priority: .emergency) {
            self.bind()
        }
        getThreeColumnsSettings(tryLocal: true)
        getThreeColumnsSettings(tryLocal: false)
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.getUnreadFeedsNum()
        }
    }

    var fixedDataSource: [FilterItemModel] {
        return dependency.fixedDataSource
    }

    var dataSource: [FilterItemModel] {
        return dependency.dataSource
    }

    func showFlagInCommonlyUsedFiltersIfNeed() {
        // 条件: 常用分组项未超上限 + 分组项不包括标记 + 分组侧栏有标记分组 + 标记分组Action == .unknown
        guard fixedDataSource.count < FeedThreeColumnConfig.fixedItemsMaxNum,
              fixedDataSource.first(where: { $0.type == .flag }) == nil,
              let flagItem = dataSource.first(where: { $0.type == .flag }),
              flagItem.action == .unknownAction else { return }

        // 临时内存新增标记数据，保证端上UI展示正常
        var tempArray = fixedDataSource
        tempArray.append(flagItem)
        dependency.localChangeCommonlyFilters(tempArray)

        // 触发接口更新常用分组数据
        let firstTabs = AllFeedListViewModel.getFirstTabs()
        var filters = fixedDataSource.compactMap { filterItem -> Feed_V1_FeedFilter? in
            if firstTabs.contains(filterItem.type) || filterItem.type == .unknown {
                return nil
            }
            var filter = Feed_V1_FeedFilter()
            filter.filterType = filterItem.type
            return filter
        }

        dependency.showFlagInCommonlyUsedFilters(filters)
    }
}
