//
//  FilterDataStore+DataHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/18.
//

import Foundation
import RustPB

extension FilterDataStore {
    func updateFilterList(_ filtersModel: FiltersModel) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.mapsInChildThread.removeAll()
            self.dataCacheInChildThread.removeAll()
            self.fixedDataInChildThread.removeAll()
            self.displayRuleMapInChildThread.removeAll()
            var usedFilters: [FilterItemModel]
            var fixedFilters: [FilterItemModel]
            let showMute = FeedMuteConfig.localShowMute(userResolver: self.userResolver, filtersModel.enable, filtersModel.showMute)
            usedFilters = filtersModel.usedFilters
            fixedFilters = filtersModel.commonlyUsedFilters.compactMap { item -> FilterItemModel? in
                return item
            }

            usedFilters.forEach { filter in
                self.mapsInChildThread[filter.type] = filter
            }
            fixedFilters.forEach { filter in
                self.mapsInChildThread[filter.type] = filter
            }

            self.dataCacheInChildThread = usedFilters
            self.fixedDataInChildThread = fixedFilters

            self.displayRuleMapInChildThread = filtersModel.msgDisplaySettingMap
            self.updateShowMute(showMute)
            self.refresh(usedFilters, fixedFilters, Array(self.mapsInChildThread.values.map({ $0 })), self.displayRuleMapInChildThread)
        }
        queue.executeOnChildThread(task)
    }

    func updateUnread(_ filtersInfo: [Feed_V1_FeedFilter.TypeEnum: PushFeedFilterInfo]) {
        let task = { [weak self] in
            guard let self = self else { return }
            guard !self.dataCacheInChildThread.isEmpty else { return }
            filtersInfo.forEach { (type: Feed_V1_FeedFilter.TypeEnum, filter: PushFeedFilterInfo) in
                guard let localFilter = self.mapsInChildThread[type] else { return }
                guard filter.unread != localFilter.unread else { return }
                let replacedFilter = localFilter.updateUnread(filter.unread)
                self.mapsInChildThread[type] = replacedFilter
                if let index = self.dataCacheInChildThread.firstIndex(where: { $0.type == localFilter.type }) {
                    self.dataCacheInChildThread.replaceSubrange(index..<(index + 1), with: [replacedFilter])
                }
                if let index = self.fixedDataInChildThread.firstIndex(where: { $0.type == localFilter.type }) {
                    self.fixedDataInChildThread.replaceSubrange(index..<(index + 1), with: [replacedFilter])
                }
            }
            self.refresh(self.dataCacheInChildThread, self.fixedDataInChildThread, Array(self.mapsInChildThread.values.map({ $0 })))
        }
        queue.executeOnChildThread(task)
    }

    func updatePushFeed(pushFeedPreview: PushFeedPreview) {
        FeedDataQueue.executeOnMainThread {
            self.pushFeedPreview = pushFeedPreview
        }
    }

    func isNeedReload(_ newFilters: [FilterItemModel], _ nowFilters: [FilterItemModel]) -> Bool {
        if nowFilters.count != newFilters.count {
            return true
        }
        for i in 0..<nowFilters.count {
            let newItem = newFilters[i]
            let nowItem = nowFilters[i]
            if newItem.type != nowItem.type ||
                newItem.unread != nowItem.unread ||
                newItem.name != nowItem.name ||
                newItem.action != nowItem.action {
                return true
            }
        }
        return false
    }
}
