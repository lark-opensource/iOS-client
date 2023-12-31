//
//  SearchMainAppTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSearchCore
import LarkSearchFilter
import LarkSDKInterface
import UniverseDesignEmpty
import SuiteAppConfig
import LarkContainer

struct SearchMainAppTabConfig: SearchTabConfigurable {
    let tab: SearchTab
    let userResolver: LarkContainer.UserResolver
    init(resolver: LarkContainer.UserResolver, tab: SearchTab) {
        self.userResolver = resolver
        self.tab = tab
    }
    var scene: SearchSceneSection = .rustScene(.searchOpenAppScene)

    var searchLocation: String { "apps" }

    var supportedFilters: [SearchFilter] { [] }

    var commonlyUsedFilters: [SearchFilter] = []

    var supportNoQuery: Bool { false }

    var universalRecommendType: UniversalRecommendType {
        if SearchFeatureGatingKey.CommonRecommend.app.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
            return .show([.app], SearchScene.searchOpenAppScene.protobufName())
        }
        return .none
    }

    var supportFeedback: Bool { false }

    var supportLoadMore: Bool { true }

    var resultViewBackgroundColor: UIColor { .ud.bgBody }

    var filterBarStyle: FilterBarStyle { .light }

    var emptyDiplayState: SearchEmptyDiplayState {
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_SearchAppPlaceholder, emptyPlaceholderImage: UDEmptyType.noApplication.defaultImage())
    }

    var tabType: SearchTabType { .subResults(.appResults) }

    // 暂时不支持应用 默认用 main
    var historyType: SearchHistoryInfoSource { .appTab }

    var shouldRequestBasedOnResult: Bool { false }

    var recommendFilterTypes: [FilterInTab] { [] }

    var sourceKey: String? { nil }

    var shouldShowJumpMore: Bool { false }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
