//
//  SearchOpenTabConfig.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSearchFilter
import UniverseDesignEmpty
import LarkSearchCore

struct SearchOpenTabConfig: SearchTabConfigurable {
    let info: SearchTab.OpenSearch
    let tab: SearchTab
    var scene: SearchSceneSection = .rustScene(.searchOpenSearchScene)

    var searchLocation: String {
        return tab.isOpenSearchEmail ? "emails" : "slash"
    }

    var allCalendarItems: [MainSearchCalendarItem] = []

    var supportedFilters: [SearchFilter] {
        return info.filters
    }

    var commonlyUsedFilters: [SearchFilter] = []

    var supportNoQuery: Bool { false }

    var universalRecommendType: UniversalRecommendType {
        // 未来增加推荐页时需要考虑leanMode
        return .none
    }

    var supportFeedback: Bool { false }

    // 目前只支持了日程，需要支持日程和邮件
    var supportLoadMore: Bool {
        if case .open(let openSearch) = tab {
            if let bizKey = openSearch.bizKey, let param = openSearch.requestParam {
                return !(bizKey == .calendar && param.mod == .noPage)
            }
        }
        return true
    }

    var requestPageSize: Int {
        if case .open(let openSearch) = tab {
            if let bizKey = openSearch.bizKey,
               bizKey == .calendar,
               let param = openSearch.requestParam {
                return Int(param.pageSize)
            }
        }
        return 15
    }

    var isOpenSearchCalendar: Bool {
        return tab.isOpenSearchCalendar
    }

    var resultViewBackgroundColor: UIColor {
        switch info.resultType {
        case .customization:
            return .ud.bgBase
        case .slashCommand:
            return .ud.bgBody
        @unknown default:
            return .ud.bgBody
        }
    }

    var filterBarStyle: FilterBarStyle { .light }

    var emptyDiplayState: SearchEmptyDiplayState {
        return .placeholder(emptyTitle: BundleI18n.LarkSearch.Lark_Search_UseKeyWordToSearch, emptyPlaceholderImage: UDEmptyType.defaultPage.defaultImage())
    }

    var tabType: SearchTabType { .subResults(.other) }

    // 暂时不支持开放搜索 默认用 main
    var historyType: SearchHistoryInfoSource { .openSearchTab }

    var shouldRequestBasedOnResult: Bool { false }

    var recommendFilterTypes: [FilterInTab] { [] }

    var sourceKey: String? { nil }

    var shouldShowJumpMore: Bool { false }

    func cellFactory(forResult result: SearchResultType) -> SearchCellFactory {
        return result.cellFactory
    }
}
