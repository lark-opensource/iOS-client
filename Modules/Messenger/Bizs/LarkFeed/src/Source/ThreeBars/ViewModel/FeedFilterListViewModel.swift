//
//  FeedFilterListViewModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import Foundation
import RustPB

final class FeedFilterListViewModel {
    let dependency: FeedFilterListDependency
    var currentSelection: FeedFilterSelection {
        didSet {
            self.dependency.updateFilterSelection(currentSelection)
        }
    }

    init(dependency: FeedFilterListDependency) {
        self.dependency = dependency
        self.currentSelection = self.dependency.currentSelection
    }

    func getSubTabId(_ type: Feed_V1_FeedFilter.TypeEnum) -> String? {
        guard let subTab = self.dependency.subTab, subTab.type == type else {
            return nil
        }
        return subTab.tabId
    }

    func setSubTabId(_ type: Feed_V1_FeedFilter.TypeEnum, subId: String) {
        guard self.dependency.multiLevelTabs.contains(type) else { return }
        self.dependency.recordSubSelectedTab(subTab: FilterSubSelectedTab(type: type, tabId: subId))
    }

    func resetSubTabId() {
        self.dependency.recordSubSelectedTab(subTab: nil)
    }
}
