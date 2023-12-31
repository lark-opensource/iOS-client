//
//  SearchIntentionCapsuleApi.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/6/30.
//

import Foundation
import ServerPB
import RxSwift
import RxRelay
import LarkSearchCore
import LKCommonsLogging
import LarkContainer
import LarkStorage
import LarkSearchFilter
import LarkRustClient

// 推荐胶囊的获取, 在(当前只支持Message 和 Docs两个Tab),Tab, query, filter value 发生变化时，拉取推荐胶囊
final class SearchMainIntentionCapsuleApi {
    static var logger = Logger.log(SearchMainIntentionCapsuleApi.self, category: "LarkSearch.SearchMainIntentionCapsuleApi")
    private let rustService: RustService

    init(rustService: RustService) {
        self.rustService = rustService
    }

    func pullRecommendCapsules(withTab tab: SearchMainTabService.Tab,
                                 withInput input: SearcherInput) -> Observable<ServerPB_Usearch_PullRecommendCapsuleDataResponse> {
        var request = ServerPB_Usearch_PullRecommendCapsuleDataRequest()
        var searchAction = ServerPB_Usearch_SearchAction()
        searchAction.tab = tab.type
        if tab.type == .openSearchTab {
            searchAction.appID = tab.appID
        }
        searchAction.query = input.query
        searchAction.filters = input.filters.compactMap({ filter in
            let filterAction = filter.convertToServerPBSearchActionFilter()
            return filterAction.typedFilter != nil ? filterAction : nil
        })
        request.searchAction = [searchAction]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .pullRecommendCapsuleData)
    }

    func resetRecommendCapsule(withCapsuleInfo info: ServerPB_Usearch_CapsuleInfo) -> Observable<ServerPB_Usearch_ResetRecommendFilterCountResponse> {
        var request = ServerPB_Usearch_ResetRecommendFilterCountRequest()
        request.capsuleInfo = info
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .resetRecommendFilterCount)
    }
}
