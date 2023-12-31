//
//  SearchTabConfigable.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
//import LarkSearchFilter
//import LarkSDKInterface
import ServerPB
import UIKit

enum SearchEmptyDiplayState {
    case none
    case placeholder(emptyTitle: String, emptyPlaceholderImage: UIImage)
}

enum UniversalRecommendType: Equatable {
    case none
    case show([ServerPB_Usearch_SearchEntityType], String)
}

enum SearchTabType {
    enum SubResultType {
        /// 联系人
        case chatterResults
        /// 消息
        case messageResults
        /// 群组
        case chatResults
        /// 云文档
        case docResults
        case appResults ///应用
        case other
    }
    // 大搜tab
    case topResults
    case subResults(SubResultType)
}

extension SearchTabType: Equatable {
    // swiftlint:disable all
    static func ==(lhs: SearchTabType, rhs: SearchTabType) -> Bool {
        switch(lhs, rhs) {
        case (.topResults, .topResults):
            return true
        case (.subResults(let lhsType), .subResults(let rhsType)):
            return lhsType == rhsType
        default:
            return false
        }
    }
    //swiftlint:enable all
}
//protocol SearchTabConfigable {
//    var scene: SearchSceneSection { get set }
//    var searchLocation: String { get } // 埋点用
//    var supportedFilters: [SearchFilter] { get }
//    var commonlyUsedFilters: [SearchFilter] { get set } //常用筛选器
//    var supportNoQuery: Bool { get } // 是否支持无 query 搜索
//    var supportFeedback: Bool { get }
//    var emptyDiplayState: SearchEmptyDiplayState { get }
//    var tabType: SearchTabType { get }
//    var universalRecommendType: UniversalRecommendType { get }
//    var supportLoadMore: Bool { get }
//    var requestPageSize: Int { get }
//    var resultViewBackgroundColor: UIColor { get }
//    var resultTableViewHorzontalPadding: CGFloat? { get }
//    var filterBarStyle: FilterBarStyle { get }
//    var tab: SearchTab { get }
//
//    var needAutoHideFilter: Bool { get }
//
//    // 搜索历史相关
//    var historyType: SearchHistoryInfoSource { get }
//
//    // SoureMaker 相关
//    var shouldRequestBasedOnResult: Bool { get }
//    var recommendFilterTypes: [FilterInTab] { get }
//    var sourceKey: String? { get }
//
//    var shouldShowJumpMore: Bool { get }
//    var enableSpotlight: Bool { get }
//
//    // cell factory
//    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory
//}

//extension SearchTabConfigable {
//    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
//        return cellFactory(forResult: item.searchResult).cellType(for: item)
//    }
//
//    var supportUniversalRecommend: Bool {
//        return universalRecommendType != .none
//    }
//
//    var needAutoHideFilter: Bool { false }
//
//    var resultTableViewHorzontalPadding: CGFloat? { nil }
//
//    var enableSpotlight: Bool { false }
//
//    var requestPageSize: Int { 15 }
//}

//extension SearchResultType {
//    var cellFactory: SearchCellFactory {
//        switch type {
//        case .chatter, .cryptoP2PChat, .shieldP2PChat:
//            return SearchChatterCellFactory()
//        case .chat:
//            return SearchAdvancedChatCellFactory()
//        case .thread:
//            return SearchTopicCellFactory()
//        case .message:
//            return SearchMessageCellFactory()
//        case .oncall:
//            return SearchOncallCellFactory()
//        case .openApp, .bot, .facility:
//            return SearchAppCellFactory()
//        case .doc:
//            return SearchDocCellFactory()
//        case .wiki:
//            return SearchWikiCellFactory()
//        case .box:
//            return SearchBoxCellFactory()
//        case .external:
//            return SearchExternalCellFactory()
//        case .QACard:
//            return SearchCardCellFactory()
//        case .customization:
//            return SearchCardCellFactory()
//        case .link:
//            return SearchLinkCellFactory()
//        case .slashCommand, .calendarEvent, .email:
//            // 日程邮箱特化的开放搜索
//            return SearchOpenCellFactory()
//        case .openSearchJumpMore:
//            return SearchJumpMoreCellFactory()
//        default:
//            // 默认用 Chatter 兜底
//            return SearchChatterCellFactory()
//        }
//    }
//}
