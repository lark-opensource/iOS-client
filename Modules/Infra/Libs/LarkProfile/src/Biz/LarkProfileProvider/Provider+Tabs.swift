//
//  Provider+Tabs.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/27.
//

import Foundation
import RxSwift
import RxCocoa
import EENavigator
import SwiftProtobuf
import LarkMessengerInterface
import UniverseDesignToast
import LarkUIKit
import UniverseDesignDialog
import ThreadSafeDataStructure

extension LarkProfileDataProvider {
    func updateTabItems() {
        guard let userProfile = userProfile else {
            return
        }
        tabsLock.lock()
        defer { tabsLock.unlock() }
        var factoryTabs: SafeArray<ProfileTabItem> = [] + .semaphore
        if !tabItems.isEmpty {
            factory?.createTabs(by: userProfile, context: self.context, provider: self).forEach({ tabItem in
                var item = tabItem
                if item.supportReuse {
                    for t in self.tabItems.getImmutableCopy() {
                        if t.identifier == item.identifier, let larkTab = t.profileTab as? LarkProfileTab {
                            larkTab.update(userProfile, context: self.context)
                            item.profileTab = larkTab
                        }
                    }
                }
                factoryTabs.append(item)
            })
        } else {
            factory?.createTabs(by: userProfile, context: self.context, provider: self).forEach({ tabItem in
                factoryTabs.append(tabItem)
            })
        }

        tabItems.removeAll()

        for item in factoryTabs.getImmutableCopy() {
            tabItems.append(item)
        }
        LarkProfileDataProvider.logger.info("update tabItems: \(tabItems.count) tabOrders: \(userProfile.tabOrders.count)")
    }

    public func getIndexBy(identifier: String) -> Int? {
        let items = tabItems.getImmutableCopy().map({
            return $0.identifier
        })
        return items.firstIndex(of: identifier)
    }

    public func numberOfTabs() -> Int {
        return tabItems.count
    }

    public func titleOfTabs() -> [String] {
        return tabItems.map { tab -> String in
            return tab.title
        }
    }

    public func identifierOfTabs() -> [String] {
        return tabItems.map { tab -> String in
            return tab.identifier
        }
    }

    public func getTabBy(index: Int) -> ProfileTab {
        if tabItems[index].profileTab == nil, let callback = tabItems[index].profileCallBack {
            tabItems[index].profileTab = callback()
        }

        return tabItems[index].profileTab ?? ProfileBaseTab()
    }
}
