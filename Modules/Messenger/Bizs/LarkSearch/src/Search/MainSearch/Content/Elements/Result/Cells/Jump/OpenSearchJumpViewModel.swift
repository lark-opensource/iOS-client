//
//  OpenSearchJumpViewModel.swift
//  LarkSearch
//
//  Created by bytedance on 2022/3/9.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import LarkCore
import LarkSDKInterface
import LarkSearchCore
import LarkSceneManager

final class OpenSearchJumpViewModel: SearchCellViewModel {
    let searchResult: SearchResultType

    var searchClickInfo: String { return "open_search" }

    var resultTypeInfo: String { return "more_results" }

    var resultTagInfo: String { return "slash_command_section" }

    var searchRouteResponder: SearchRootViewModelProtocol?

    init(searchResult: SearchResultType) {
        self.searchResult = searchResult
    }

    convenience init(searchResult: SearchResultType,
                     searchRouteResponder: SearchRootViewModelProtocol?) {
        self.init(searchResult: searchResult)
        self.searchRouteResponder = searchRouteResponder
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        guard
            let appLink = (searchResult as? OpenJumpResult)?.appLink,
            let appLinkEncoded = appLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: appLinkEncoded),
            let target = url.queryParameters.first(where: { $0.key == "target" })?.value,
            let actionType = SearchSectionAction(rawValue: target) else {
                return nil
        }
        let query = url.queryParameters.first(where: { $0.key == "query" })?.value ?? ""
        let appId = url.queryParameters.first(where: { $0.key == "commandId" })?.value ?? ""
        var title = url.queryParameters.first(where: { $0.key == "title" })?.value ?? "Open Search" + appId
        if title.isEmpty {
            title = "Open Search" + appId
        }
        // 目前跳转只支持了 openSearch
        if actionType == .openSearch || actionType == .slashCommand {
            if let searchRouteResponder = searchRouteResponder {
                let input = SearcherInput(query: query)
                let type = SearchTab.open(SearchTab.OpenSearch(id: appId, label: title, icon: nil, resultType: .slashCommand, filters: []))
                let routeParam = SearchRouteParam(type: type, input: input)
                searchRouteResponder.route(withParam: routeParam)
            }
        }

        // 跳转到tab类history就是空
        return nil
    }
    func supportDragScene() -> Scene? {
        return nil
    }
    func supprtPadStyle() -> Bool {
        return false
    }
}
