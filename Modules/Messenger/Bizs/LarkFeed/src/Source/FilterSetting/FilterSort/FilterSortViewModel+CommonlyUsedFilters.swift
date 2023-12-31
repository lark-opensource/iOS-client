//
//  FeedFilterViewModel+CommonlyUsedFilters.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/13.
//

import Foundation
import RustPB
import LarkOpenFeed

extension FilterSortViewModel {
    func deleteCommonlyUsedFilter(_ type: Feed_V1_FeedFilter.TypeEnum) {
        guard let sectionVM = itemsMap[.commonlyFilters], sectionVM.section < items.count,
              var item = sectionVM.rows.first as? FeedCommonlyFilterModel else { return }

        let filterItems = item.filterItems.compactMap({ item -> FeedCommonlyFilterItem? in
            if item.filterItem.type == type {
                return nil
            }
            return item
        })
        item.filterItems = filterItems
        var tempItems = items
        tempItems[sectionVM.section] = refreshDataForSectionVM(sectionVM, [item])
        update(tempItems)

        reloadSection(.commonlyFilters)
    }

    func selectCommonlyUsedFilter() {
        guard let allFilters = filtersModel?.allFilters else { return }
        guard let sectionVM = itemsMap[.commonlyFilters], sectionVM.section < items.count,
              var item = sectionVM.rows.first as? FeedCommonlyFilterModel,
              item.filterItems.count < FeedThreeColumnConfig.fixedItemsMaxNum  else { return }

        let commonlyUsedFilters = item.filterItems.compactMap { item -> FilterItemModel? in
            if let filterItem = item.filterItem as? FilterItemModel {
                return filterItem
            }
            return nil
        }

        var useMap = [Feed_V1_FeedFilter.TypeEnum: FilterItemModel]()
        commonlyUsedFilters.forEach { filter in
            useMap[filter.type] = filter
        }

        var unAdds = [FilterItemModel]()
        allFilters.forEach { filter in
            if useMap[filter.type] == nil {
                unAdds.append(filter)
            }
        }
        pushSelectVCRelay.accept(unAdds)
    }

    func addCommonlyUsedFilter(_ type: Feed_V1_FeedFilter.TypeEnum) {
        guard let sectionVM = itemsMap[.commonlyFilters], sectionVM.section < items.count,
              var item = sectionVM.rows.first as? FeedCommonlyFilterModel,
              item.filterItems.count < FeedThreeColumnConfig.fixedItemsMaxNum,
              !item.filterItems.contains(where: { $0.filterItem.type == type }),
              let name = FeedFilterTabSourceFactory.source(for: type)?.titleProvider() else { return }

        var filterItems = item.filterItems
        filterItems.append(FeedCommonlyFilterItem(filterItem: FilterItemModel(type: type, name: name), editEnable: true))
        item.filterItems = filterItems
        var tempItems = items
        tempItems[sectionVM.section] = refreshDataForSectionVM(sectionVM, [item])
        update(tempItems)

        reloadSection(.commonlyFilters)
    }
}
