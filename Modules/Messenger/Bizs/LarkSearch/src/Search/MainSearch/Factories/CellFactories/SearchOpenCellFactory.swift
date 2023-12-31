//
//  SearchOpenCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer
import LKCommonsLogging

struct SearchOpenCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        if case .slash(let meta) = item.searchResult.meta, meta.slashCommand == .filter {
            return OpenSearchFilterTableViewCell.self
        } else if item.searchResult.type == .customization {
            return CustomizationCardTableViewCell.self
        }
        if item.searchResult.bid.elementsEqual("lark"),
           item.searchResult.entityType.elementsEqual("calendar-event") {
            if let viewModel = item as? CalendarSearchViewModel, viewModel.tab != .main {
                return CalendarSearchTableViewCell.self
            } else if item as? CalendarSearchDayTitleViewModel != nil {
                return CalendarSearchDayTitleTableViewCell.self
            } else if item as? CalendarSearchDividingLineViewModel != nil {
                return CalendarSearchDividingLineTableViewCell.self
            }
        }
        if let viewModel = item as? EmailSearchViewModel, viewModel.tab != .main {
            return EmailSearchTableViewCell.self
        }
        return OpenSearchNewTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        if searchResult.type == .customization {
            return StoreCardSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router, isMainTab: false)
        }
        if let result = searchResult as? Search.Result, context.tab != .main {
            if result.bid.elementsEqual("lark"), result.entityType.elementsEqual("calendar-event"),
               !result.renderData.isEmpty, let renderData = result.renderData.data(using: .utf8) {
                do {
                    let renderModel = try JSONDecoder().decode(CalendarSearchRenderDataModel.self, from: renderData)
                    let resultModel = CalendarSearchViewModel(userResolver: userResolver, searchResult: result, router: context.router, renderDataModel: renderModel)
                    resultModel.tab = context.tab
                    return resultModel
                } catch {
                    Logger.log(SearchOpenCellFactory.self, category: "Module.IM.Search").error("[LarkSearch] mainSearch calendar renderData is error \(error)")
                }
            }
            if result.type == .email {
                let resultModel = EmailSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
                resultModel.tab = context.tab
                return resultModel
            }
        }
        return OpenSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router, context: context)
    }
}
