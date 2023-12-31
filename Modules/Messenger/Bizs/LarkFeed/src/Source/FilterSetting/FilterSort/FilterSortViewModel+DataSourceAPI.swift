//
//  FilterSortViewModel+DataSourceAPI.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/13.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import UniverseDesignToast
import LarkSDKInterface

extension FilterSortViewModel {
    func getFilters(on window: UIWindow?) {
        _getFilters(tryLocal: true, on: window)
    }

    private func _getFilters(tryLocal: Bool, on window: UIWindow?) {
        dependency.getFilters(tryLocal: tryLocal)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self = self else { return }
                self.filtersModel = filter
                self.isSwitchOpen = filter.enable
                self.msgDisplaySettingMap = filter.msgDisplaySettingMap.filter({
                    self.dependency.enableDisplayRuleSetting($0.key)
                })
                self.updateFilterList(filter)
            }, onError: { [weak window] _ in
                guard let window = window else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Legacy_FailedtoLoadTryLater, on: window)
            }).disposed(by: disposeBag)
    }

    private func updateFilterList(_ filtersModel: FiltersModel) {
        let showMute = FeedMuteConfig.localShowMute(userResolver: userResolver, filtersModel.enable, filtersModel.showMute)
        let allFilters = filtersModel.allFilters
        var allMap = [Feed_V1_FeedFilter.TypeEnum: FilterItemModel]()
        allFilters.forEach { filter in
            allMap[filter.type] = filter
        }

        var commonlyUsedFilters = filtersModel.commonlyUsedFilters
        if commonlyUsedFilters.isEmpty {
            let type = AllFeedListViewModel.getFirstTab(showMute: showMute)
            let name = showMute ? BundleI18n.LarkFeed.Lark_Feed_FilterChats : BundleI18n.LarkFeed.Lark_Feed_FilterAll
            let allItemModel = FilterItemModel(type: type, name: name)
            commonlyUsedFilters.insert(allItemModel, at: 0)
        }

        var usedFilters = filtersModel.usedFilters
        if usedFilters.isEmpty {
            let type = AllFeedListViewModel.getFirstTab(showMute: showMute)
            let name = showMute ? BundleI18n.LarkFeed.Lark_Feed_FilterChats : BundleI18n.LarkFeed.Lark_Feed_FilterAll
            let allItemModel = FilterItemModel(type: type, name: name)
            usedFilters.insert(allItemModel, at: 0)
        }

        var useMap = [Feed_V1_FeedFilter.TypeEnum: FilterItemModel]()
        usedFilters.forEach { filter in
            useMap[filter.type] = filter
        }

        var unAdds = [FilterItemModel]()
        allFilters.forEach { filter in
            if useMap[filter.type] == nil {
                unAdds.append(filter)
            }
        }

        let items = createDataSourceItems(commonlyUsedFilters, usedFilters, unAdds)
        update(items)
        targetIndex = getTargetIndex(unAdds)
        let message = "feedlog/filter/setting/update. updateFilterList: "
            + "filterEnable: \(filtersModel.enable), "
            + "showMute: \(showMute), "
            + "commonlyUsedFilters: count: \(commonlyUsedFilters.count), info: \(commonlyUsedFilters.map({ $0.type })), "
            + "usedFilters: count: \(usedFilters.count), info: \(usedFilters.map({ $0.type })), "
            + "allFilters: count: \(allFilters.count), info: \(allFilters.map({ $0.type })), "
            + "unAdds: count: \(unAdds.count), info: \(unAdds.map({ $0.type })), "
            + "targetIndex: \(targetIndex?.row ?? -1)"
        FeedContext.log.info(message)

        self.dataSourceSubject.onNext([usedFilters, unAdds])
    }

    func saveFilterEditor(_ filtersModel: FiltersModel) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        var commonlyFilters: [FilterItemModel]?
        if dependency.showCommonlyFilters,
           let sectionVM = itemsMap[.commonlyFilters], sectionVM.section < items.count,
           let commonlyFilterModel = sectionVM.rows.first as? FeedCommonlyFilterModel {
            commonlyFilters = commonlyFilterModel.filterItems.compactMap({ $0.filterItem })
        }

        var filters: [FilterItemModel] = []
        var infoList: [String] = []
        if let sectionVM = itemsMap[.delete], sectionVM.section < items.count {
            filters = sectionVM.rows.compactMap({
                if let item = $0 as? FeedFilterModel {
                    return item.filterItem
                }
                return nil
            })
            infoList = sectionVM.rows.compactMap({
                if let item = $0 as? FeedFilterModel {
                    return FiltersModel.tabName(item.filterItem.type)
                }
                return nil
            })
        }
        // 标签在消息分组的展示设置
        let needSaveFeedGroupRule = filters.contains(where: { $0.type == .tag })
        let list = infoList.joined(separator: ",")
        FeedTeaTrack.trackFilterEditSave(list)
        FeedTracker.GroupEdit.Click.Save(displayRuleChanged: displayRuleChanged, labelSecondaryRuleChanged: labelSecondaryRuleChanged)
        let filterEnable = needSwitch ? isSwitchOpen : nil
        return dependency.saveFeedFiltersSetting(filterEnable,
                                                 commonlyFilters,
                                                 filters,
                                                 msgDisplaySettingMap,
                                                 needSaveFeedGroupRule ? feedGroupDisplaySettingMap : nil)
    }
}
