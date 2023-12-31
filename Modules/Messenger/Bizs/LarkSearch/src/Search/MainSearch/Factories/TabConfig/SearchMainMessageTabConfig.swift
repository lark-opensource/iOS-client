//
//  SearchMainMessageTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSearchFilter
import LarkSetting
import LarkSDKInterface
import LarkSearchCore
import UniverseDesignEmpty

struct SearchMainMessageTabConfig: SearchTabConfigurable {
    let chatMode: ChatFilterMode
    let tab: SearchTab

    init(chatMode: ChatFilterMode, tab: SearchTab) {
        self.chatMode = chatMode
        self.tab = tab
        scene = chatMode == .normal ? .searchMessageOnly : .rustScene(.searchMessages)
    }

    var scene: SearchSceneSection

    var searchLocation: String { "messages" }

    var supportedFilters: [SearchFilter] {
        var searchFilters: [SearchFilter] = []
        searchFilters.append(.chatter(mode: chatMode, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false))
        /// 新增with筛选器
        searchFilters.append(.withUsers([]))
        searchFilters.append(.chat(mode: chatMode, picker: []))
        searchFilters.append(.date(date: nil, source: .message))
        if SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
            searchFilters.append(.messageAttachmentType(.unknownAttachmentType))
        } else {
            searchFilters.append(.messageType(.all))
        }
        searchFilters.append(.messageChatType(.all))
        searchFilters.append(.messageMatch([]))
        return searchFilters
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

    var resultTableViewHorzontalPadding: CGFloat? { nil }

    var filterBarStyle: FilterBarStyle { .light }

    var emptyDiplayState: SearchEmptyDiplayState {
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_SearchMessagePlaceholder, emptyPlaceholderImage: UDEmptyType.noMessageLog.defaultImage())
    }

    var tabType: SearchTabType { .subResults(.messageResults) }

    var historyType: SearchHistoryInfoSource { .messageTab }

    var shouldRequestBasedOnResult: Bool { true }

    var recommendFilterTypes: [FilterInTab] {
        return [.msgSender]
    }

    var sourceKey: String? { nil }

    var shouldShowJumpMore: Bool { false }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
