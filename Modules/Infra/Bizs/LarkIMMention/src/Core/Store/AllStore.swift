//
//  AllStore.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/21.
//

import Foundation

class AllStore: MentionStore {
    override func handleRecommendReuslt(_ res: ProviderResult) {
        super.handleRecommendReuslt(res)
        var items = [IMMentionOptionType]()
        if context.isEnableAtAll, context.chatUserCount > 0 {
            items.append(IMPickerOption.all(count: context.chatUserCount, showChatUserCount: context.showChatUserCount))
        }
        let flapItems = res.result.flatMap { $0 }
        var itemCache = [String: String]()
        for i in flapItems {
            guard let id = i.id else { continue }
            if itemCache[id] == nil {
                items.append(i)
            }
            itemCache[id] = id
        }
        currentState.hasMore = false
        items = items.mapTrackInfo(pageType: .all, chooseType: .recommend)
        currentItems = .init(sections: [.init(items: items)])
    }
    
    override func handleSearchReuslt(_ res: ProviderResult) {
        currentState.isLoading = false
        currentState.error = nil
        currentState.hasMore = false
        if res.isEmpty {
            currentState.isShowSkeleton = true
            currentItems = generateSkeletonItems()
        } else {
            currentState.isShowSkeleton = false
            var items = [IMMentionOptionType]()
            let flapItems = res.result.flatMap { $0 }
            var itemCache = [String: String]()
            for i in flapItems {
                guard let id = i.id else { continue }
                if itemCache[id] == nil {
                    items.append(i)
                }
                itemCache[id] = id
            }
            items = items.mapTrackInfo(pageType: .all, chooseType: .search)
            currentItems = .init(sections: [.init(items: items)])
        }
    }
    
    override func handleComplete() {
        if let res = self.currentRes {
            if res.res.isEmpty {
                currentState.isShowSkeleton = false
                currentState.error = .noResult
                currentItems = .init(sections: [.init()])
            }
        } else {
            currentState.isShowSkeleton = false
            currentState.error = .noResult
            currentItems = .init(sections: [.init()])
        }
    }
}


extension Collection where Element == IMMentionOptionType {
    func mapTrackInfo(pageType: PageType, chooseType: ChooseType) -> [IMMentionOptionType] {
        return self.map {
            var i = $0
            i.trackerInfo.pageType = pageType
            i.trackerInfo.chooseType = chooseType
            return i
        }
    }
}
