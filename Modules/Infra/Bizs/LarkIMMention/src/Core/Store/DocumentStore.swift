//
//  DocumentStore.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/21.
//

import Foundation

class DocumentStore: MentionStore {
    
    override func handleStartSearch(query: String?) {
        currentState.isShowSkeleton = true
        currentState.error = nil
        currentItems = generateSkeletonItems()
    }
    
    override func handleRecommendReuslt(_ res: ProviderResult) {
        super.handleRecommendReuslt(res)
        currentItems.setTrackInfo(pageType: .doc, chooseType: .recommend)
    }
    
    override func handleSearchReuslt(_ res: ProviderResult) {
        super.handleSearchReuslt(res)
        currentItems.setTrackInfo(pageType: .doc, chooseType: .search)
    }
}
