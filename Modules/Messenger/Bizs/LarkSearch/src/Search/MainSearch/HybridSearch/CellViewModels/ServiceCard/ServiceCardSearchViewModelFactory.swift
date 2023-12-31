//
//  QACardSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by ZhangHongyun on 2021/7/14.
//

import UIKit
import Foundation
import LarkAccountInterface
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct ServiceCardSearchViewModelFactory: SearchSceneConfig {

    var searchScene: SearchSceneSection {
        return .searchServiceCard
    }

    var searchDisplayTitle: String {
        return ""
    }

    var searchDisplayImage: UIImage? {
        return nil
    }

    var searchLocation: String {
        return "ServiceCard"
    }

    var newSearchLocation: String {
        return "ServiceCard"
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        if searchResult.type == .oncall {
            guard
                let oncallAPI = try? userResolver.resolve(assert: OncallAPI.self),
                let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
            else {
                return DemoSearchCellViewModel(searchResult: searchResult)
            }
            // 卡片的结果可能会返回onCall
            return OncallSearchViewModel(userResolver: userResolver,
                                         searchResult: searchResult,
                                         router: context.router,
                                         currentChatterID: userResolver.userID,
                                         oncallAPI: oncallAPI,
                                         chatAPI: chatAPI,
                                         context: context)
        } else if searchResult.type == .ServiceCard {
            return ServiceCardSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
        } else if searchResult.type == .customization {
            switch searchResult.meta {
            case .customization(let meta) where meta.cardType == .aslLynx:
                return StoreCardSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
            case .customization(let meta) where meta.cardType == .block:
                return SearchBlockViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
            default:
            return StoreCardSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
            }
        } else {
            return QACardSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
        }
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        if item.searchResult.type == .oncall {
            return OncallSearchNewTableViewCell.self
        } else if item.searchResult.type == .ServiceCard {
            return ServiceCardSearchTableViewCell.self
        } else if item.searchResult.type == .customization {
            switch item.searchResult.meta {
            case .customization(let meta) where meta.cardType == .aslLynx:
                return CustomizationCardTableViewCell.self
            case .customization(let meta) where meta.cardType == .block:
                return SearchBlockTableViewCell.self
            default: return CustomizationCardTableViewCell.self
            }
        } else {
            return QACardSearchTableViewCell.self
        }
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
