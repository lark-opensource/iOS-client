//
//  SearchMainChatterTabConfig.swift
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

struct SearchMainChatterTabConfig: SearchTabConfigurable {
    let tab: SearchTab
    init(tab: SearchTab) {
        self.tab = tab
    }
    var scene: SearchSceneSection = .rustScene(.searchChatters)

    var searchLocation: String { "contacts" }

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
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_SearchContactsPlaceholder, emptyPlaceholderImage: UDEmptyType.noContact.defaultImage())
    }

    var tabType: SearchTabType { .subResults(.chatterResults) }

    // 暂时不支持群组 默认用 main
    var historyType: SearchHistoryInfoSource { .chatterTab }

    var shouldRequestBasedOnResult: Bool { false }

    var recommendFilterTypes: [FilterInTab] { [] }

    var sourceKey: String? { nil }

    var shouldShowJumpMore: Bool { false }

    var enableSpotlight: Bool {
        return SearchFeatureGatingKey.enableSupportSpotlight.isEnabled
    }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
