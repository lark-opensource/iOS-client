//
//  SearchOncallTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSearchFilter
import LarkSDKInterface
import UniverseDesignEmpty
import LarkSearchCore

struct SearchOncallTabConfig: SearchTabConfigurable {
    let tab: SearchTab
    init(tab: SearchTab) {
        self.tab = tab
    }
    var scene: SearchSceneSection = .rustScene(.searchOncallScene)

    var searchLocation: String { "helpdesk" }

    var supportedFilters: [SearchFilter] { [] }

    var commonlyUsedFilters: [SearchFilter] = []

    var supportNoQuery: Bool { false }

    var universalRecommendType: UniversalRecommendType {
        // 未来增加推荐页时需要考虑leanMode
        return .none
    }

    var supportFeedback: Bool { false }

    var supportLoadMore: Bool { true }

    var resultViewBackgroundColor: UIColor { .ud.bgBody }

    var filterBarStyle: FilterBarStyle { .light }

    var emptyDiplayState: SearchEmptyDiplayState {
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_SearchHelpDeskPlaceholder, emptyPlaceholderImage: UDEmptyType.ccmNoWorkFlow.defaultImage())
    }

    var shouldRequestBasedOnResult: Bool { false }

    var recommendFilterTypes: [FilterInTab] { [] }

    var sourceKey: String? { nil }

    var tabType: SearchTabType { .subResults(.other) }

    // 暂时不支持服务台 默认用 main
    var historyType: SearchHistoryInfoSource { .helpdeskTab }

    var shouldShowJumpMore: Bool { false }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
