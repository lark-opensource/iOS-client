//
//  SearchMainDocTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkSearchFilter
import UniverseDesignEmpty
import LarkContainer
struct SearchMainDocTabConfig: SearchTabConfigurable {
    let tab: SearchTab
    init(tab: SearchTab) {
        self.tab = tab
    }
    var scene: SearchSceneSection = .rustScene(.searchDoc)

    var searchLocation: String { "docs" }

    var supportedFilters: [SearchFilter] {
        var filters: [SearchFilter] = []
        filters.append(.docSortType(.mostRelated))
        filters.append(.docOwnedByMe(false, Container.shared.getCurrentUserResolver().userID))
        if SearchFeatureGatingKey.docWikiFilter.isEnabled {
            filters.append(.docType(.all))
        }
        if SearchFeatureGatingKey.mainFilter.isEnabled {
            filters.append(.docFrom(fromIds: [], recommends: [], fromType: .user, isRecommendResultSelected: false))
        }
        filters.append(.docPostIn([]))
        filters.append(.docFolderIn([]))
        filters.append(.docWorkspaceIn([]))
        filters.append(.docFormat([], .main))
        filters.append(.date(date: nil, source: .doc))
        filters.append(.docContentType(.fullContent))
        filters.append(.docCreator([], Container.shared.getCurrentUserResolver().userID))
        if SearchFeatureGatingKey.docFilterSharer.isEnabled {
            filters.append(.docSharer([]))
        }
        return filters
    }

    var commonlyUsedFilters: [SearchFilter] = []

    var supportNoQuery: Bool { true }

    var universalRecommendType: UniversalRecommendType {
        // 未来增加推荐页时需要考虑leanMode
        return .none
    }

    var supportFeedback: Bool { false }

    var supportLoadMore: Bool { true }

    var resultViewBackgroundColor: UIColor { .ud.bgBody }

    var filterBarStyle: FilterBarStyle { .light }

    var emptyDiplayState: SearchEmptyDiplayState {
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_SearchSpacePlaceholder, emptyPlaceholderImage: UDEmptyType.noWiki.defaultImage())
    }

    var tabType: SearchTabType { .subResults(.docResults) }

    var historyType: SearchHistoryInfoSource { .docsTab }

    var shouldRequestBasedOnResult: Bool { true }

    var recommendFilterTypes: [FilterInTab] {
        return [.docFrom]
    }

    var sourceKey: String? { nil }

    var shouldShowJumpMore: Bool { false }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
