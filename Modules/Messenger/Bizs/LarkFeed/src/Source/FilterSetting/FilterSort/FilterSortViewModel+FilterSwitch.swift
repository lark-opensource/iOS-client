//
//  FilterSortViewModel+FilterSwitch.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/13.
//

import Foundation

extension FilterSortViewModel {
    func refreshSwitchState() {
        if let sectionVM = itemsMap[.filterSwitch], sectionVM.section < items.count,
           var item = sectionVM.rows.first as? FeedFilterEditModel {
            item.status = isSwitchOpen
            var tempItems = items
            tempItems[sectionVM.section] = refreshDataForSectionVM(sectionVM, [item])
            update(tempItems)
        }
    }

    func autoCheckSwitchState(previousUserCount: Int, nowUserCount: Int) {
        guard let sectionVM = itemsMap[.filterSwitch], sectionVM.section < items.count else { return }
        if isSwitchOpen {
            guard nowUserCount == 1 else { return }
            isSwitchOpen = false
            hudShowRelay.accept(false)
        } else {
            guard previousUserCount == 1, nowUserCount == 2 else { return }
            isSwitchOpen = true
            hudShowRelay.accept(true)
        }

        refreshSwitchState()
        reloadSwitchRelay.accept(())
        setNeedSwitch()
    }
}
