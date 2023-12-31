//
//  SearchBlockViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2022/4/14.
//

import UIKit
import Foundation
import Blockit
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging
import OPSDK
import OPBlockInterface

final class SearchBlockViewModel: SearchBlockPresentable {
    static let logger = Logger.log(SearchBlockViewModel.self, category: "LarkSearch.SearchBlockViewModel")
    let router: SearchRouter
    let blockService: BlockitService?
    let searchResult: SearchResultType

    var searchClickInfo: String {
        return ""
    }
    var resultTypeInfo: String {
        return "block"
    }

    private var blockRenderContentJson: [String: AnyObject] {
        guard case let .customization(meta) = searchResult.meta,
              meta.cardType == .block else {
                  Self.logger.error("SearchBlockViewModel wrong meta")
                  return [:]
              }
        guard let jsonData = meta.renderContent.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: jsonData, options: [])) as? [String: AnyObject] else {
                  Self.logger.error("SearchBlockViewModel JSONSerialization Error")
                  return [:]
              }
        return json
    }

    var appId: String? {
        let json = blockRenderContentJson
        guard let appId = json["appIDStr"] as? String else { return nil }
        return appId
    }

    var title: String {
        let json = blockRenderContentJson
        guard let title = json["title"] as? String else { return "" }
        return title
    }

    var blockInfo: OPBlockInfo? {
        let json = blockRenderContentJson
        guard let code = json["status"] as? Int, code == 0 else {
            Self.logger.error("SearchBlockViewModel json error")
            return nil
        }

        guard let blockID = json["blockID"] as? String,
              let blockTypeID = json["blockTypeID"] as? String,
              let sourceMeta = json["sourceMeta"] as? String else {
                  Self.logger.error("SearchBlockViewModel data error")
                  return nil
              }

        let sourceLink = json["sourceLink"] as? String ?? ""
        let sourceData = json["sourceData"] as? String
        let i18nSummary = json["i18nSummary"] as? String ?? ""
        let i18nPreview = json["i18nPreview"] as? String ?? ""

        let sourceDataObject: [AnyHashable: Any]
        if let sourceDataString = sourceData, let sourceData = sourceDataString.data(using: .utf8) {
            sourceDataObject = ((try? JSONSerialization.jsonObject(with: sourceData, options: .allowFragments)) as? [AnyHashable: Any]) ?? [:]
        } else {
            sourceDataObject = [:]
        }

        let sourceMetaObject: [AnyHashable: Any]
        if let sourceMeta = sourceMeta.data(using: .utf8) {
            sourceMetaObject = ((try? JSONSerialization.jsonObject(with: sourceMeta, options: .allowFragments)) as? [AnyHashable: Any]) ?? [:]
        } else {
            sourceMetaObject = [:]
        }

        let blockInfo = OPBlockInfo(blockID: blockID,
                                  blockTypeID: blockTypeID,
                                  sourceLink: sourceLink,
                                  sourceData: sourceDataObject,
                                  sourceMeta: sourceMetaObject,
                                  i18nPreview: i18nPreview,
                                  i18nSummary: i18nSummary)
        return blockInfo
    }

    var indexPath: IndexPath?

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        return nil
    }

    func supprtPadStyle() -> Bool {
        return false
    }

    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter) {
        self.searchResult = searchResult
        self.router = router
        self.blockService = try? userResolver.resolve(assert: BlockitService.self)
    }
}
