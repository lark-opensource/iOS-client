//
//  SearchSceneConfig.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import Swinject
import LarkSearchFilter
import LarkAccountInterface
import LarkMessengerInterface
import LarkSDKInterface
import LarkSearchCore
import RustPB
import LarkContainer

final class SearchViewModelContext {
    struct ClickInfo {
        let sessionId: String?
        let imprId: String?
        let query: String?
        let searchLocation: String?
        let sceneType: String?
        let filters: [SearchFilter]
    }

    let router: SearchRouter
    let tab: SearchTab
    var clickInfo: (() -> (ClickInfo))?

    var searchRouteResponder: SearchRootViewModelProtocol?
    init(router: SearchRouter, tab: SearchTab) {
        self.router = router
        self.tab = tab
    }

    convenience init(router: SearchRouter,
                     tab: SearchTab,
                     searchRouteResponder: SearchRootViewModelProtocol) {
        self.init(router: router, tab: tab)
        self.searchRouteResponder = searchRouteResponder
    }
}

protocol SearchCellProtocol: UITableViewCell {
    func setup(withViewModel viewModel: SearchCellPresentable, currentAccount: User?)
}

protocol SearchTableViewCellProtocol: SearchCellProtocol {
    func set(viewModel: SearchCellViewModel,
             currentAccount: User?,
             searchText: String?)
    var viewModel: SearchCellViewModel? { get }
    func cellWillDisplay()
}

extension SearchTableViewCellProtocol {
    func setup(withViewModel viewModel: SearchCellPresentable, currentAccount: User?) {
        guard let vm = viewModel as? SearchCellViewModel else { return }
        set(viewModel: vm, currentAccount: currentAccount, searchText: "")
    }
    func cellWillDisplay() { }
}

/// 大搜场景（包括高级搜索）的cell工厂
protocol MainSearchCellFactory {
    /// 聚合类返回的cellType延迟到cellForRow时，目前就大搜用. 使用这个方法时，不用searchCellType相关的调用
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type
    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel
}

typealias FilterInTab = Search_V1_FilterInTab

protocol SearchSceneConfig: MainSearchCellFactory {
    var searchScene: SearchSceneSection { get }

    var noQuerySource: SearchHistoryInfoSource { get }

    var searchDisplayTitle: String { get }

    var searchDisplayImage: UIImage? { get }

    var supportedFilters: [SearchFilter] { get }

    var supportNoQuery: Bool { get }

    var searchLocation: String { get }

    var newSearchLocation: String { get }

    var supportLocalSearch: Bool { get }

    var historyType: SearchHistoryInfoSource { get }

    var recommendFilterTypes: [FilterInTab] { get }

    var userResolver: UserResolver { get }
}

extension SearchSceneConfig {
    var supportedFilters: [SearchFilter] { return [] }

    var noQuerySource: SearchHistoryInfoSource { return .smartSearchTab }

    var supportNoQuery: Bool { return false }

    var historyType: SearchHistoryInfoSource { return .smartSearchTab }

    // 本地搜索: 支持本地搜索的有：小组、群组、消息、话题、联系人
    var supportLocalSearch: Bool { return false }
}

extension SearchTableViewCellProtocol {
    var controller: UIViewController? {
        for case let vc as UIViewController in Search.UIResponderIterator(start: self) {
            return vc
        }
        return nil
    }
}
