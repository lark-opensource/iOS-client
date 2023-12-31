//
//  SearchMainTabService.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/4/11.
//

import Foundation
import ServerPB
import RxSwift
import RxRelay
import LarkSearchCore
import LKCommonsLogging
import LarkContainer
import LarkStorage
import LarkSearchFilter
import LarkRustClient
import UniverseDesignIcon
import RustPB

/// 控制自定义Tab的类型
final class SearchMainTabService: UserResolverWrapper {
    static var logger = Logger.log(SearchMainTabService.self, category: "LarkSearch.SearchMainTabService")
    // 因为只是本地缓存，主要用来避免重启重进时没有上一次的数据。重要性不高
    static let store = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("Search"))
    @KVConfig(key: KVKey("mainTab"), store: store)
    static var mainTabCache: [Data]?
    @KVConfig(key: KVKey("availableTab"), store: store)
    static var availableTabCache: [Data]?
    @KVConfig(key: KVKey("commonlyUsedFiltersDataLists"), store: store)
    static var commonlyUsedFiltersDataListsCache: [Data]?

    @ScopedInjectedLazy var searchDependency: SearchDependency?
    typealias Tab = ServerPB_Usearch_SearchTab
    @ScopedInjectedLazy var rustService: RustService?
    let bag = DisposeBag()
    /// nil代表加载初始数据, 不包含综合
    /// 这是服务端的原始数据. 一般不应该用这个数据，优先考虑使用currentTabs,
    let tabs = BehaviorRelay<[Tab]?>(value: SearchMainTabService.loadTabs())
    let availableTabs = BehaviorRelay<[Tab]?>(value: SearchMainTabService.loadAvailableTabs())
    let commonlyUsedFiltersData = BehaviorRelay<[CommonlyUsedFilterDataList]?>(value: SearchMainTabService.loadCommonlyUsedFilters())
    let shouldClearJumpTabSubject = PublishSubject<Bool>()
    var allCalendarItems: [MainSearchCalendarItem] = []
    var tabsFilters: [SearchTab: [SearchFilter]] = [:]
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    private func updateTabs(tabs: [Tab]) {
        guard !equal(newTabs: tabs) else { return } // 避免不变的通知
        self.tabs.accept(tabs)
        Self.save(tabs: tabs)
    }
    func equal(newTabs: [Tab]) -> Bool {
        if let current = self.tabs.value, current.count == newTabs.count,
            zip(current, newTabs).allSatisfy({ $0.identity == $1.identity }) {
            return true
        }
        return false
    }

    func getCompleteSearchTab(type: SearchTab) -> SearchTab? {
        let currentAvailableTabs = currentAvailableTabs()
        for tab in currentAvailableTabs {
            if tab == type {
                return tab
            }
        }
        // AvailableTabs 中不包含综搜
        // 日程和邮箱迁移fg耦合 会导致AvailableTabs 中邮箱和日程数据不准，所以加一个默认值判断
        let defaultTabs = SearchTab.defaultTypes().filter({ self.isSupportTab(tab: $0) })
        for tab in defaultTabs {
            if tab == type {
                return tab
            }
        }
        return nil
    }

    // 需要和入口支持的tab类型保持一致
    func currentTabs() -> [SearchTab] {
        guard let tabs = tabs.value else {
            return SearchTab.defaultTypes().filter({ self.isSupportTab(tab: $0) })
        }

        var current = [SearchTab.main] // 综合始终在最前面
        var saw: Set = [SearchTab.main]
        func append(_ tab: SearchTab) {
            if saw.insert(tab).inserted {
                current.append(tab)
            }
        }
        tabs.compactMap({ SearchTab($0) }).forEach(append)
        // 默认的tab必须显示，没有的话补充到末尾
        SearchTab.defaultTypes().forEach(append)
        current = current.filter({ self.isSupportTab(tab: $0) })
        return current
    }

    // 是不包含mainTab的
    func currentAvailableTabs() -> [SearchTab] {
        guard let tabs = availableTabs.value else { return [] }
        return tabs.compactMap({ SearchTab($0) }).filter({ self.isSupportTab(tab: $0) })
    }

    // MARK: server API
    func pullTabs() {
        var request = ServerPB_Usearch_PullUserSearchTabsRequest()
        if SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver)
            || SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver) {
            request.isQueryTemplate = true
        }
        rustService?.sendPassThroughAsyncRequest(request, serCommand: .pullUserSearchTabs)
        .subscribe(onNext: { [weak self](response: ServerPB_Usearch_PullUserSearchTabsResponse) in
            Self.logger.info("pull search tabs: \(response.searchTabs.map { $0.shortDescription }.joined(separator: ", "))")
            guard let self = self else { return }
            let searchTabs = self.filterTabByCondition(tabs: response.searchTabs)
            self.updateTabs(tabs: searchTabs)
        }).disposed(by: bag)
    }

    func put(tabs: [SearchTab]) -> Observable<()> {
        // cast将SearchTab转化为Tab, 开放搜索是没有带上筛选器的，因为服务端的json解析有问题，会导致保存失败，待服务端解决 @yuguosen
        let requestTabs: [Tab] = tabs.compactMap { $0.cast() }
        // 不变不用请求
        if equal(newTabs: requestTabs) { return .just(()) }
        var request = ServerPB_Usearch_PutUserSearchTabsRequest()
        if SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver)
            || SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver) {
            request.isQueryTemplate = true
        }
        request.searchTabs = requestTabs
        return ((rustService?.sendPassThroughAsyncRequest(request, serCommand: .putUserSearchTabs) ?? .empty())
         as Observable<ServerPB_Usearch_PutUserSearchTabsResponse>)
        .do(onNext: { [weak self] _ in
            Self.logger.info("put search tabs: \(requestTabs.map { $0.shortDescription }.joined(separator: ", "))")
            guard let self = self else { return }
            var completeTabs: [Tab] = []
            // 不完整的数据会导致丢筛选器，需要使用availableTabs补全
            if !SearchFeatureGatingKey.searchLoadingBugfixProtectFg.isUserEnabled(userResolver: userResolver),
               let availableTabs = availableTabs.value, !availableTabs.isEmpty {
                completeTabs = requestTabs.map { requestTab in
                    return availableTabs.first(where: { completeTab in
                        if requestTab.type == completeTab.type {
                            if requestTab.type == .openSearchTab {
                                return requestTab.appID == completeTab.appID
                            }
                            return true
                        }
                        return false
                    }) ?? requestTab
                }
            } else {
                completeTabs = requestTabs
            }
            self.updateTabs(tabs: completeTabs)
        }, onError: {
            Self.logger.warn("put search tabs error: \(requestTabs.map { $0.shortDescription }.joined(separator: ", "))", error: $0)
        }).map { _ in }
    }

    func pullAvailableTabsAndSave() {
        self.available().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (tabs) in
            guard let self = self else { return }
            self.availableTabs.accept(tabs)
            Self.saveAvailable(tabs: tabs)
            self.initTabFilters()
        }).disposed(by: bag)
    }

    func initTabFilters() {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
        guard let tabs = self.availableTabs.value else { return }
        tabsFilters = [:]
        for tab in tabs {
            if let searchTab = SearchTab(tab), case.message = searchTab {
                for capsultInfo in tab.highlightSelectedCapsules {
                    //本期只支持记忆「不看机器人」
                    if case.filterValue = capsultInfo.capsuleType {
                        var selectFilters: [SearchFilter] = []
                        for filter in capsultInfo.searchAction.filters {
                            if filter.messageMatchScope.scopeTypes.contains(.blockBotMessage) {
                                selectFilters.append(.messageMatch([.excludeBot]))
                            }
                        }
                        var resultTab = ServerPB_Usearch_SearchTab()
                        resultTab.type = capsultInfo.searchAction.tab
                        resultTab.appID = capsultInfo.searchAction.appID
                        if !selectFilters.isEmpty, let selectTab = SearchTab(resultTab) {
                            tabsFilters[selectTab] = selectFilters
                        }
                    }
                }
            }
        }
    }

    func filterTabByCondition(tabs: [Tab]) -> [Tab] {
        var resultTabs: [Tab] = tabs
        if SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver) {
            resultTabs = resultTabs.filter({ tab in
                return tab.type != .calendarTab
            })
        } else {
            resultTabs = resultTabs.filter({ tab in
                return tab.bizKey != .calendar
            })
        }
        if SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver) {
            resultTabs = resultTabs.filter({ tab in
                return tab.type != .emailTab
            })
        } else {
            resultTabs = resultTabs.filter({ tab in
                return tab.bizKey != .email
            })
        }
        Self.logger.info("filterTabByCondition search tabs: \(resultTabs.map { $0.shortDescription }.joined(separator: ", "))")
        return resultTabs
    }

    func updateTabsFilter(searchTab: SearchTab, filters: [SearchFilter]) {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
        if filters.isEmpty {
            if tabsFilters.keys.contains(searchTab) {
                tabsFilters.removeValue(forKey: searchTab)
            }
        } else {
            tabsFilters[searchTab] = filters
        }
    }

    // 部分Tab依赖fg或其他业务提供的能力
    func isSupportTab(tab: SearchTab) -> Bool {
        switch tab {
        case .main, .message, .doc, .chatter, .chat, .app:
            return true
        case .calendar:
            return !SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver)
        case .email:
            return (searchDependency?.hasEmailService() ?? false) && !SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver)
        case .oncall:
            return SearchFeatureGatingKey.oncallEnable.isUserEnabled(userResolver: userResolver) || SearchFeatureGatingKey.oncallPreGA.isUserEnabled(userResolver: userResolver)
        case .open(let openTab):
            if openTab.bizKey == .calendar,
               !SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver) {
                return false
            }
            if openTab.bizKey == .email,
               (!SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver) || !(searchDependency?.hasEmailService() ?? false)) {
                return false
            }
            return true
        case .wiki:
            return false
        default:
            return false
        }
    }

    //拉取常用筛选器
    func pullCommonlyUsedFilters() {
        guard SearchFeatureGatingKey.enableCommonlyUsedFilter.isUserEnabled(userResolver: userResolver) else { return }
        var request = ServerPB_Usearch_PullRecommendFilterDataRequest()
        request.tabList = [.messageTab, .docsTab]
        rustService?.sendPassThroughAsyncRequest(request, serCommand: .pullRecommendFilterData)
            .subscribe(onNext: { [weak self] (response: ServerPB_Usearch_PullRecommendFilterDataResponse) in
                guard let self = self else { return }
                if response.dataList.isEmpty {
                    //拉取空也要更新缓存
                    Self.logger.info("pull commonly used filters is empty")
                }
                self.commonlyUsedFiltersData.accept(response.dataList)
                Self.saveCommonlyUsedFiltersData(dataLists: response.dataList)
            }, onError: { (error) in
                Self.logger.error("pull commonly used filters with error", error: error)
            }).disposed(by: bag)
    }
    /// 可用的Tab，注意排重
    func available() -> Observable<[Tab]> {
        var request = ServerPB_Usearch_PullAvailableSearchTabsRequest()
        if SearchFeatureGatingKey.searchCalendarMigration.isUserEnabled(userResolver: userResolver)
            || SearchFeatureGatingKey.searchEmailMigration.isUserEnabled(userResolver: userResolver) {
            request.isQueryTemplate = true
        }
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .pullAvailableSearchTabs)
        .map { [weak self] (response: ServerPB_Usearch_PullAvailableSearchTabsResponse) in
            guard let self = self else { return response.searchTabs }
            Self.logger.info("pull available search tabs: \(response.searchTabs.map { $0.shortDescription }.joined(separator: ", "))")
            return self.filterTabByCondition(tabs: response.searchTabs)
        }
        .observeOn(MainScheduler.instance) ?? .empty()
    }

    func getAllCalendars() {
        searchDependency?.getAllCalendarsForSearchBiz(isNeedSelectedState: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] subscribeCalendarsItems in
                guard let self = self else { return }
                guard !subscribeCalendarsItems.isEmpty else { return }
                self.allCalendarItems = MainSearchCalendarItem.sortCalendarItems(items: subscribeCalendarsItems)
            }).disposed(by: bag)
    }

    func putFilterDataRequest(searchAction: ServerPB_Usearch_SearchAction) {
        guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
        var request = ServerPB_Usearch_PutFilterDataRequest()
        request.searchAction = searchAction
        rustService?.sendPassThroughAsyncRequest(request, serCommand: .putFilterData)
        .subscribe(onNext: { (response: ServerPB_Usearch_PutFilterDataResponse) in
            Self.logger.info("put filter data request: \(response.putState)")
        }, onError: { (error) in
            Self.logger.error("put filter data request with error", error: error)
        }).disposed(by: bag)
    }

    var commonlyUsedFilters: [CommonlyUsedFilterDataList] {
        guard SearchFeatureGatingKey.enableCommonlyUsedFilter.isUserEnabled(userResolver: userResolver) else { return [] }
        return Self.loadCommonlyUsedFilters() ?? []
    }

    @discardableResult
    private static func save(tabs: [Tab]) -> Bool {
        do {
            mainTabCache = try tabs.map { try $0.serializedData() }
            return true
        } catch {
            Self.logger.error("update tabs with error: \(tabs.map { $0.shortDescription }.joined(separator: ", "))", error: error)
        }
        return false
    }
    private static func loadTabs() -> [Tab]? {
        do {
            return try mainTabCache?.map { data in try Tab(serializedData: data) }
        } catch {
            Self.logger.error("load tabs with error", error: error)
        }
        return nil
    }
    @discardableResult
    private static func saveAvailable(tabs: [Tab]) -> Bool {
        do {
            availableTabCache = try tabs.map { try $0.serializedData() }
            return true
        } catch {
            Self.logger.error("update available tabs with error: \(tabs.map { $0.shortDescription }.joined(separator: ", "))", error: error)
        }
        return false
    }
    private static func loadAvailableTabs() -> [Tab]? {
        do {
            return try availableTabCache?.map { data in try Tab(serializedData: data) }
        } catch {
            Self.logger.error("load available tabs with error", error: error)
        }
        return nil
    }
    @discardableResult
    private static func saveCommonlyUsedFiltersData(dataLists: [CommonlyUsedFilterDataList]) -> Bool {
        do {
            commonlyUsedFiltersDataListsCache = try dataLists.map { try $0.serializedData() }
            return true
        } catch {
            Self.logger.error("update commonly used filters data Lists with error", error: error)
        }
        return false
    }
    private static func loadCommonlyUsedFilters() -> [CommonlyUsedFilterDataList]? {
        do {
            return try commonlyUsedFiltersDataListsCache?.map { data in try CommonlyUsedFilterDataList(serializedData: data) }
        } catch {
            Self.logger.error("load commonly used filters data Lists with error", error: error)
        }
        return nil
    }
}

// 实际用于展示的Tab
public enum SearchTab: Identifiable, Hashable {
    case main
    case message, doc, wiki, chatter, chat, app, calendar, email
    case oncall
    case topic, thread
    case pano(label: String)
    enum RequestPageMod {
        case normal // 正常翻页
        case noPage // 不翻页，相当于只有1页
    }
    struct RequestParam {
        var pageSize: Int32
        var mod: RequestPageMod
    }
    public struct OpenSearch {
        var id: String
        var label: String
        var icon: String?
        var resultType: ServerPB_Usearch_SearchTab.ResultType
        var filters: [SearchFilter]
        var bizKey: ServerPB_Usearch_SearchTab.BizKey?
        var requestParam: RequestParam?
    }
    case open(OpenSearch)

    var title: String {
        switch self {
        case .main:     return BundleI18n.LarkSearch.Lark_Search_TopResults
        case .app:      return BundleI18n.LarkSearch.Lark_Search_Apps
        case .message:  return BundleI18n.LarkSearch.Lark_Search_TitleChatRecord
        case .doc:      return BundleI18n.LarkSearch.Lark_Search_SpaceFragmentTitle
        case .oncall:   return BundleI18n.LarkSearch.Lark_Search_HelpDesk
        case .wiki:     return BundleI18n.LarkSearch.Lark_Search_Wiki
        case .chatter:  return BundleI18n.LarkSearch.Lark_Legacy_Contact
        case .chat:     return BundleI18n.LarkSearch.Lark_Legacy_Group
        case .calendar: return BundleI18n.LarkSearch.Lark_Search_Calendar
        case .topic:    return BundleI18n.LarkSearch.Lark_Search_Posts
        case .thread:   return BundleI18n.LarkSearch.Lark_Search_Channels
        case .email:    return BundleI18n.LarkSearch.Lark_Legacy_MailTab
        case .open(let v): return v.label
        case .pano(label: let v): return v
        }
    }

    var icon: UIImage? {
        switch self {
        case .app: return UDIcon.tabAppColorful
        case .message: return UDIcon.tabChatColorful
        case .doc, .wiki: return UDIcon.tabDriveColorful
        case .chatter: return UDIcon.tabContactsColorful
        case .chat: return UDIcon.tabGroupColorful
        case .calendar: return UDIcon.tabCalendarColorful
        case .email: return UDIcon.tabMailColorful
        case .oncall: return UDIcon.helpdeskColorful
        default:
            return nil
        }
    }

    init?(_ tab: SearchMainTabService.Tab) {
        func getGeneralFilters(tab: SearchMainTabService.Tab) -> [SearchFilter] {
            return tab.platformCustomFilters.map { (info) -> SearchFilter? in
                switch info.filterType {
                case .userFilter:
                    return .general(.user(info, []))
                case .timeFilter:
                    return .general(.date(info, nil))
                case .searchableFilter, .predefineEnumFilter:
                    switch info.optionMode {
                    case .single: return .general(.single(info, nil))
                    case .multiple: return .general(.multiple(info, []))
                    @unknown default:
                        return nil
                    }
                case .calendarFilter:
                    return .general(.calendar(info, []))
                case .userChatFilter:
                    return .general(.userChat(info, []))
                case .mailUser:
                    return .general(.mailUser(info, []))
                case .inputTextFilter:
                    return .general(.inputTextFilter(info, []))
                @unknown default:
                    return nil
                }
            }.compactMap({ $0 })
        }
        switch tab.type {
        case .messageTab: self = .message
        case .docsTab: self = .doc
        case .wikiTab: self = .wiki
        case .chatTab: self = .chat
        case .calendarTab: self = .calendar
        case .appTab: self = .app
        case .chatterTab: self = .chatter
        case .openSearchTab:
            var requestParam: RequestParam?
            if tab.hasParams, tab.params.hasPageSize, tab.params.hasMode {
                let pageSize = tab.params.pageSize > 0 ? tab.params.pageSize : 15
                switch tab.params.mode {
                case .normal: requestParam = RequestParam(pageSize: pageSize, mod: .normal)
                case .noPage: requestParam = RequestParam(pageSize: pageSize, mod: .noPage)
                case .unknown: requestParam = nil
                @unknown default:
                    requestParam = nil
                    assertionFailure("@unknown case")
                }
            }
            self = .open(.init(id: tab.appID,
                               label: tab.label,
                               icon: tab.hasIconURL ? tab.iconURL : nil,
                               resultType: tab.resultType,
                               filters: getGeneralFilters(tab: tab),
                               bizKey: tab.bizKey,
                               requestParam: requestParam))
        case .emailTab: self = .email
        case .panoTab: self = .pano(label: tab.label)
        case .helpdeskTab: self = .oncall
        // NOTE: 除了不知道的，格式尽量保留，哪怕UI暂时没适配.., 这样可以转换回传set数据
        // UI适配用另一个supported参数控制
        case .unknownTab, .smartSearchTab:
            fallthrough // use unknown default setting to fix warning
        @unknown default:
        return nil
        }
    }
    func cast() -> SearchMainTabService.Tab? {
        switch self {
        case .message: return .init(type: .messageTab, label: self.title)
        case .doc: return .init(type: .docsTab, label: self.title)
        case .wiki: return .init(type: .wikiTab, label: self.title)
        case .chatter: return .init(type: .chatterTab, label: self.title)
        case .chat: return .init(type: .chatTab, label: self.title)
        case .app: return .init(type: .appTab, label: self.title)
        case .calendar: return .init(type: .calendarTab, label: self.title)
        case .oncall: return .init(type: .helpdeskTab, label: self.title)
        case .email: return .init(type: .emailTab, label: self.title)
        case .pano(let label): return .init(type: .panoTab, label: label)
        case .open(let v):
            var tab = SearchMainTabService.Tab()
            tab.type = .openSearchTab
            tab.appID = v.id
            if let icon = v.icon { tab.iconURL = icon }
            tab.label = v.label
            return tab
        // TODO: oncall: tabs需要支持，否则对应的Tab是调不动的..
        case .topic, .thread, .main:
            return nil
        }
    }
    static func defaultTypes() -> [SearchTab] {
        var childTypes: [SearchTab] = [.main]

        childTypes.append(.message)
        childTypes.append(.doc)
        childTypes.append(.wiki)
        childTypes.append(.email)
        childTypes.append(.app)
        childTypes.append(.chatter)
        childTypes.append(.chat)
        childTypes.append(.calendar)
        childTypes.append(.oncall)
        return childTypes
    }

    /// 用于判断去重的关键字段
    public enum Identity: Hashable {
        case main
        case message, doc, wiki, chatter, chat, app, calendar
        case oncall
        case topic, thread
        case email, pano
        case open(id: String)
    }
    public var id: Identity {
        switch self {
        case .main: return .main
        case .message: return .message
        case .doc: return .doc
        case .wiki: return .wiki
        case .chatter: return .chatter
        case .chat: return .chat
        case .app: return .app
        case .calendar: return .calendar
        case .oncall: return .oncall
        case .topic: return .topic
        case .thread: return .thread
        case .email: return .email
        case .pano: return .pano
        case .open(let v): return .open(id: v.id)
        }
    }
    var isOpenSearchCalendar: Bool {
        if case .open(let openSearch) = self, openSearch.bizKey == .calendar {
            return true
        } else {
            return false
        }
    }

    var isOpenSearchEmail: Bool {
        if case .open(let openSearch) = self, openSearch.bizKey == .email {
            return true
        } else {
            return false
        }
    }
    var shortDescription: String {
        if case .open(let openSearch) = self {
            return "<type: open, id: \(openSearch.id)>"
        } else {
            return "<type: \(self)>"
        }
    }

    public static func == (lhs: SearchTab, rhs: SearchTab) -> Bool { return lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
}

extension ServerPB_Usearch_SearchTab {
    struct Identity: Hashable {
        var type: ServerPB_Searches_SearchTabName
        var appID: String?
        var title: String
        var platformCustomFilters: [ServerPB.ServerPB_Searches_PlatformSearchFilter.CustomFilterInfo]
    }
    var identity: Identity { Identity(type: type, appID: appID, title: label, platformCustomFilters: platformCustomFilters) }
    init(type: ServerPB_Searches_SearchTabName, label: String? = nil) {
        self = .init()
        self.type = type
        if let label = label {
            self.label = label
        }
    }
    var shortDescription: String {
        if type == .openSearchTab {
            return "<type: \(self.type.rawValue), id: \(self.appID)>"
        } else {
            return "<type: \(self.type.rawValue)>"
        }
    }
}
