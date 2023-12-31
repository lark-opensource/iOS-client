//
//  SearchMainChatTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSearchFilter
import LarkFeatureGating
import LarkFeatureSwitch
import LarkSDKInterface
import LarkSearchCore
import UniverseDesignEmpty

struct SearchMainChatTabConfig: SearchTabConfigurable {
    let chatMode: ChatFilterMode
    let tab: SearchTab

    init(chatMode: ChatFilterMode, tab: SearchTab) {
        self.chatMode = chatMode
        self.tab = tab
        switch chatMode {
        case .thread:
            self.scene = .searchThreadInAdvanceOnly
        case .normal:
            self.scene = .searchChatInAdvanceOnly
        @unknown default:
            self.scene = .rustScene(.searchChatsInAdvanceScene)
        }
    }

    var scene: SearchSceneSection

    var searchLocation: String { "groups" }

    var supportedFilters: [SearchFilter] {
        var filterType: [SearchFilter] = []
        Feature.on(.searchFilter).apply(on: {
            switch self.chatMode {
            case .thread:
                filterType = [.threadType(.all),
                              .chatMemeber(mode: self.chatMode, picker: [])]
            @unknown default:
                if SearchFeatureGatingKey.groupSortFilter.isEnabled {
                    filterType.append(.groupSortType(.mostRelated))
                }
                filterType.append(contentsOf: [.chatType([]), .chatMemeber(mode: self.chatMode, picker: [])])
            }
        }, off: {})
        return filterType
    }

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
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_SearchGroupPlaceholder, emptyPlaceholderImage: UDEmptyType.noContent.defaultImage())
    }

    var tabType: SearchTabType { .subResults(.chatResults) }

    var historyType: SearchHistoryInfoSource { .chatTab }

    var shouldRequestBasedOnResult: Bool { true }

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
