//
//  SearchMainTopResultsTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkSearchFilter
import LarkMessengerInterface
import UniverseDesignEmpty
import LarkSetting
import SuiteAppConfig
import LarkContainer

struct SearchMainTopResultsTabConfig: SearchTabConfigurable {

    let sourceOfSearch: SourceOfSearch

    let tab: SearchTab

    let userResolver: LarkContainer.UserResolver
    init(resolver: LarkContainer.UserResolver,
         sourceOfSearch: SourceOfSearch,
         tab: SearchTab) {
        self.userResolver = resolver
        self.sourceOfSearch = sourceOfSearch
        self.tab = tab
    }

    static let maxItemNumber = 3
    static let openSearchSectionMaxItemNumber = 6
    var scene: SearchSceneSection = .rustScene(.smartSearch)

    var searchLocation: String { "quick_search" }

    var supportedFilters: [SearchFilter] {
        var filters = [SearchFilter]()
        if SearchFeatureGatingKey.mainFilter.isEnabled {
            filters.append(.commonFilter(.mainFrom(fromIds: [], recommends: [], fromType: .user, isRecommendResultSelected: false)))
            filters.append(.commonFilter(.mainWith([])))
            filters.append(.commonFilter(.mainIn(inIds: [])))
            filters.append(.commonFilter(.mainDate(date: nil)))
        }
        return filters
    }

    var commonlyUsedFilters: [SearchFilter] = []

    var supportNoQuery: Bool { false }

    var universalRecommendType: UniversalRecommendType {
        if SearchFeatureGatingKey.CommonRecommend.main.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
            return .show([.app, .user, .groupChat, .bot], SearchScene.smartSearch.protobufName())
        }
        return .none
    }

    var supportFeedback: Bool { true }

    var supportLoadMore: Bool { false }

    var resultViewBackgroundColor: UIColor { .ud.bgBase }

    var resultTableViewHorzontalPadding: CGFloat? { 8 }

    var filterBarStyle: FilterBarStyle { .dark }

    var emptyDiplayState: SearchEmptyDiplayState {
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_UseKeyWordToSearch, emptyPlaceholderImage: UDEmptyType.defaultPage.defaultImage())
    }

    var tabType: SearchTabType { .topResults }

    var needAutoHideFilter: Bool { true }

    var historyType: SearchHistoryInfoSource { .smartSearchTab }

    var shouldRequestBasedOnResult: Bool { false }

    var recommendFilterTypes: [FilterInTab] {
        var recommendFilterTypes: [FilterInTab] = []
        recommendFilterTypes.append(.smartUser)
        return recommendFilterTypes
    }

    var sourceKey: String? { sourceOfSearch.sourceKey }

    var shouldShowJumpMore: Bool {
        return !AppConfigManager.shared.leanModeIsOn
    }

    var enableSpotlight: Bool {
        return SearchFeatureGatingKey.enableSupportSpotlight.isEnabled
    }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
