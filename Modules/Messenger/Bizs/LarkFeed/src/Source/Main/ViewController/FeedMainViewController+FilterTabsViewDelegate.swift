//
//  FeedMainViewController+FilterTabsViewDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import Foundation
import UniverseDesignTabs
import RustPB
import RxSwift
import RxCocoa

extension FeedMainViewController: FilterTabsViewDelegate {

    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) {
        let dataSource = getDataSource()
        guard index < dataSource.count else {
            FeedContext.log.info("feedlog/filter/didClickSelectedItem. datasourceCount: \(dataSource.count), index: \(index)")
            return
        }
        let newFilterItem = dataSource[index]
        guard newFilterItem.type != mainViewModel.currentFilterType else { return }
        let lastFilterType = mainViewModel.currentFilterType
        // 单击其他filterItem
        changeTab(newFilterItem.type, .fixedViewTabClick)
        FeedTracker.ThreeColumns.Click.fixedTabClick(newFilterItem.type)
    }

    func didEnterSetting(_ tabsView: UDTabsView, index: Int) {
        FeedTracker.Main.Click.Setting(filter: mainViewModel.currentFilterType)
    }

    private func getDataSource() -> [FilterItemModel] {
        return filterTabView.mainViewModel.dataStore.commonlyFiltersDS
    }
}
