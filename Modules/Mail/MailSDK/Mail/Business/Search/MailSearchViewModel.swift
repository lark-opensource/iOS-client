//
//  SearchDataCenter.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/6.
//

import Foundation
import RxSwift
import Reachability
import RxRelay
import RustPB
import Homeric

typealias MailSearchSearchStrategy = Email_Client_V1_MailMixedSearchRequest.Strategy

enum MailSearchResultState {
    case loading
    case result(dataArray: [MailSearchCallBack])
    case noResult(searchText: String)
    case fail(reason: String)
}

enum MailSearchHintFrom: String {
    case other = "mail_other"
    case title = "mail_title"
    case file = "mail_file"
}

struct MailSearchInfo {
    let offlineSearch: Bool
    let isLoadMore: Bool
    let searchText: String
    let hasMore: Bool
    let hasTrashOrSpam: Bool
    var hintFrom: [MailSearchHintFrom] = []

    func hintFromResult() -> String {
        if hintFrom.isEmpty {
            return MailSearchHintFrom.other.rawValue
        }
        if hintFrom.count == 1 {
            return hintFrom.first?.rawValue ?? MailSearchHintFrom.other.rawValue
        }
        return "[" + hintFrom.map({ $0.rawValue }).joined(separator: ",") + "]"
    }
}

enum MailSearchViewControllerState {
    case empty
    case history
    case result(state: MailSearchResultState, info: MailSearchInfo)
    case clientResult(state: MailClientSearchResultState, info: MailSearchInfo)
}

protocol  MailSearchDataCenterDelegate: AnyObject {
    func resultViewModelDidUpdate(threadId: String, viewModel: MailSearchResultCellViewModel)
}

protocol MailSearchViewModel {
    var state: BehaviorRelay<MailSearchViewControllerState> { get }
    var refreshList: BehaviorRelay<Bool> { get }
    var searchSession: MailSearchSession { get }
    var offset: Int { get }
    var hasMore: Bool { get }
    var remoteHasMore: Bool { get }
    var nextBegin: Int { get }
    var strategy: MailSearchSearchStrategy { get }
    var sectionData: [MailSearchSectionData] { get set }
    var lastSearchText: String { get set }
    var scene: MailSearchScene { get set }
    var offlineSearch: Bool { get set }

    // action
    func updateCommonSession(commonSession: String)
    func search(keyword: String, filters: [MailSearchFilter], begin: Int, loadMore: Bool, forceReload: Bool, fromLabel: String)
    func searchRemote(keyword: String, begin: Int, loadMore: Bool, debounceInterval: Int,  fromLabel: String)
    func getItem(_ indexPath: IndexPath) -> MailSearchCallBack?
    func updateItem(_ indexPath: IndexPath, item: MailSearchCallBack)
    func getSectionItems(_ section: Int) -> [MailSearchCallBack]
    func getCellIndexPath(_ threadId: String) -> IndexPath?
    func allItems() -> [MailSearchCallBack]
    func trickLoadMore(_ indexPath: IndexPath) -> Bool
    func searchAbort()

    func getResultItems() -> [MailSearchCallBack]
    func setResultItems(_ items: [MailSearchCallBack])
    func getRemoteResultItems() -> [MailSearchCallBack]
    func setRemoteResultItems(_ items: [MailSearchCallBack])
    func removeAllResultItems()
    func removeAllRemoteResultItems()
}

// 相同的方法, 默认实现
extension MailSearchViewModel {
    func getItem(_ indexPath: IndexPath) -> MailSearchCallBack? {
        guard indexPath.section < sectionData.count else {
            mailAssertionFailure("[mail_client_search] indexPath.section >= sectionData.count !")
            return nil
        }
        guard indexPath.row < sectionData[indexPath.section].searchResultItems.count else {
            mailAssertionFailure("[mail_client_search] indexPath.row >= sectionData[indexPath.section].searchResultItems.count !")
            return nil
        }
        return sectionData[indexPath.section].searchResultItems[indexPath.row]
    }

    func getSectionItems(_ section: Int) -> [MailSearchCallBack] {
        if section < sectionData.count {
            return sectionData[section].searchResultItems
        }
        return []
    }

    func getCellIndexPath(_ threadId: String) -> IndexPath? {
        for (sectionIndex, section) in sectionData.enumerated() {
            if let rowIndex = section.searchResultItems.firstIndex(where: { $0.viewModel.threadId == threadId }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }

    func allItems() -> [MailSearchCallBack] {
        return sectionData.flatMap({ $0.searchResultItems })
    }

    func trickLoadMore(_ indexPath: IndexPath) -> Bool {
        let resultItems = sectionData[indexPath.section].searchResultItems
        if indexPath.section == 0 {
            if !resultItems.isEmpty && hasMore && indexPath.row == resultItems.count - 5 {
                return true
            }
        } else {
            if !resultItems.isEmpty && remoteHasMore && indexPath.row == resultItems.count - 5 {
                return true
            }
        }
        return false
    }

    func getResultItems() -> [MailSearchCallBack] {
        return sectionData[0].searchResultItems
    }

    func searchAbort() {}
}

struct MailSearchSectionData {
    var searchResultItems: [MailSearchCallBack]
    // headerStatus 待扩展
}

class MailSearchDataCenter: MailSearchViewModel {
    
    // MARK: ViewModel interface
    var state: BehaviorRelay<MailSearchViewControllerState> // 在第一次被人订阅的时候会先吐默认值
    var commonSession = ""
    var refreshList: BehaviorRelay<Bool>

    // MARK: property
    let searchSession = MailSearchSession()
    private let settingConfig: MailSettingConfigProxy?
    private let preloadServices: MailPreloadServicesProtocol
    var lastSearchText: String = ""
    var scene: MailSearchScene = .inMailTab
    private var disposeBag = DisposeBag()
    var hasMore: Bool = true
    var remoteHasMore: Bool = true
    var nextBegin: Int = 0
    var offset: Int = 1
    var strategy: MailSearchSearchStrategy = .remote
    var sectionData: [MailSearchSectionData]
    weak var delegate: MailSearchDataCenterDelegate?

    var useHistory: Bool = true
    var offlineSearch: Bool = false
    let offlineSearchFG = FeatureManager.open(FeatureKey(fgKey: .offlineSearch, openInMailClient: true))
    private var lastConnection: Reachability.Connection = .wifi
    // 正在预加载的Thread, 如果取消搜索，通过threadIDs cancel预加载
    private var preloadThreadIDs: [String] = []

    private lazy var mailSearchDataQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "MailSearchDataQueue", qos: .userInitiated)
        return queue
    }()
    private lazy var mailSearchDataScheduler: SchedulerType = {
        return SerialDispatchQueueScheduler(
            queue: mailSearchDataQueue,
            internalSerialQueueName: mailSearchDataQueue.label
        )
    }()

    init(settingConfig: MailSettingConfigProxy?,
         preloadServices: MailPreloadServicesProtocol,
         useHistory: Bool = true) {
        self.useHistory = useHistory
        self.settingConfig = settingConfig
        self.preloadServices = preloadServices
        state = BehaviorRelay(value: useHistory ? .history: .empty) // 默认展示历史搜索页
        sectionData = [MailSearchSectionData(searchResultItems: [])]
        refreshList = BehaviorRelay(value: false)
    }

    func updateItem(_ indexPath: IndexPath, item: MailSearchCallBack) {
        sectionData[indexPath.section].searchResultItems[indexPath.row] = item
    }

    func setResultItems(_ items: [MailSearchCallBack]) {
        sectionData[0].searchResultItems = items
        refreshList.accept(true)
    }

    func getRemoteResultItems() -> [MailSearchCallBack] {
        return []
    }
    func setRemoteResultItems(_ items: [MailSearchCallBack]) {}

    func removeAllResultItems() {
        sectionData[0].searchResultItems.removeAll()
    }

    func removeAllRemoteResultItems() {}

    func searchRemote(keyword: String, begin: Int, loadMore: Bool, debounceInterval: Int, fromLabel: String) {}

    func search(keyword: String, filters: [MailSearchFilter], begin: Int, loadMore: Bool, forceReload: Bool, fromLabel: String) {
        defer {
            lastSearchText = keyword
        }
        strategy = .local

        MailLogger.info("[mail_search] data-request remoteSearch keyword: \(keyword.hashValue)")
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !filters.isEmpty else {
            disposeBag = DisposeBag()
            state.accept(self.useHistory ? .history: .empty)
            MailLogger.info("[mail_search] data-request empty && filter empty")
            return
        }
        
        if offlineSearchFG {
            if !loadMore, let reach = Reachability() {
                lastConnection = reach.connection
            }
            offlineSearch = lastConnection == .none
        }
        if !loadMore || forceReload {
            searchSession.renewSession()
            hasMore = true
            if forceReload {
                nextBegin = 0
                offset = 1
            }
            if lastSearchText.isEmpty {
                state.accept(.result(state: .loading, info: MailSearchInfo(offlineSearch: offlineSearch,
                                                                           isLoadMore: loadMore,
                                                                           searchText: keyword,
                                                                           hasMore: false,
                                                                           hasTrashOrSpam: false))) // 列表空时的全新搜索。全新搜索展示loading
            }
        }
        if begin == 0 {
            offset = 1
        }
        disposeBag = DisposeBag() // 新垃圾袋，释放掉之前的请求
        let startTime = Int(1000 * Date().timeIntervalSince1970)

        MailLogger.info("[mail_search] data-request begin: \(begin) offlineSearch: \(offlineSearch) fromLabel: \(fromLabel)")
        let search = Store
            .fetcher?
            .remoteSearch(keyword: keyword, filters: filters, searchSession: searchSession.session, begin: Int64(begin), isOffline: offlineSearch, fromLabel: fromLabel)
            .subscribeOn(mailSearchDataScheduler)
        search?.map { (response) -> (MailRemoteSearchResponse, [MailSearchResultCellViewModel]) in
            return (response, response.vms)
        }.subscribe(onNext: { [weak self] (response, viewModels) in
            guard let `self` = self else { return }
            MailLogger.info("[mail_search] data-request viewModels: \(viewModels.count)")
            self.handlerSearchResponse(response: response, viewModels: viewModels,
                                       loadMore: loadMore, keyword: keyword, startTime: startTime)
        }, onError: { [weak self] (error) in
                if let `self` = self {
                    let info = MailSearchInfo(offlineSearch: self.offlineSearch, isLoadMore: loadMore,
                                              searchText: keyword, hasMore: self.hasMore, hasTrashOrSpam: false)
                    MailLogger.error("[mail_search] simpleRemoteSearch error: \(error.localizedDescription)")
                    self.state.accept(.result(state: .fail(reason: error.localizedDescription), info: info))
                }
        }, onCompleted: { [weak self] in
                guard let `self` = self, keyword == self.lastSearchText else { return }
                // TODO：还没想好干嘛，这里应该是判断搜索的列表有无数据，如果没有要回调noresult
        }).disposed(by: disposeBag)
    }

    func updateCommonSession(commonSession: String) {
        self.commonSession = commonSession
    }

    func handlerSearchResponse(response: MailRemoteSearchResponse,
                               viewModels: [MailSearchResultCellViewModel],
                               loadMore: Bool,
                               keyword: String,
                               startTime: Int) {
        self.nextBegin = Int(response.nextBegin)
        self.offset += 1
        self.hasMore = response.hasMore
        var info = MailSearchInfo(offlineSearch: offlineSearch, isLoadMore: loadMore, searchText: keyword, hasMore: self.hasMore, hasTrashOrSpam: response.containTrashOrSpam)
        let searchCallBacks = viewModels.map({ (item) -> MailSearchCallBack in
            if item.subject.contains(keyword) {
                info.hintFrom.append(.title)
            }
            if !item.attachmentNameList.isEmpty {
                info.hintFrom.append(.file)
            }
            if info.hintFrom.isEmpty {
                info.hintFrom.append(.other)
            }
            return MailSearchCallBack(viewModel: item, info: info)
        })
        MailLogger.info("[mail_saas_search] hintFrom: \(searchCallBacks.count) loadMore: \(loadMore)")
        if searchCallBacks.isEmpty && !loadMore {
            self.state.accept(.result(state: .noResult(searchText: keyword), info: info))
        } else {
            if loadMore {
                sectionData[0].searchResultItems.append(contentsOf: searchCallBacks)
            } else {
                sectionData[0].searchResultItems = searchCallBacks
            }
            self.state.accept(.result(state: .result(dataArray: searchCallBacks), info: info))
        }
        MailTracker.log(event: Homeric.ASL_SEARCH_TIME_DEV,
                        params: ["search_location": "emails",
                                 "search_id": self.searchSession.uuid,
                                 "query_length": keyword.count,
                                 "time": Int(1000 * Date().timeIntervalSince1970) - startTime,
                                 "search_session_id": self.commonSession,
                                 "request_timestamp": String(Int(Date().timeIntervalSince1970)),
                                 "scene_type": "component"])
        preloadImagesIfNeed(viewModels: viewModels)
    }

    func searchAbort() {
        // 退出搜索时取消还未开始的预加载任务
        cancelPreloadIfNeed()
    }

    private func preloadImagesIfNeed(viewModels: [MailSearchResultCellViewModel]) {
        // 1. 取消上一次触发，并且还没有开始执行的预加载任务
        cancelPreloadIfNeed()
        // 2. 开始当前搜索结果预加载
        let firstN = settingConfig?.preloadConfig?.searchPreloadCount ?? 0
        MailLogger.info("MailPreloadServices: preload first \(firstN) threads if need from seachResults")
        self.preloadThreadIDs = Array(viewModels.map { $0.threadId }.prefix(firstN))
        preloadServices.preloadImages(threadIDs: preloadThreadIDs,
                                                 labelID: Mail_LabelId_SEARCH,
                                                 source: .search)
    }

    private func cancelPreloadIfNeed() {
        for threadID in preloadThreadIDs {
            preloadServices.cancelPreload(threadID: threadID,
                                          labelID: Mail_LabelId_SEARCH,
                                          cardID: nil,
                                          ownerUserID: nil,
                                          source: .search)
        }
        preloadThreadIDs = []
    }
}

// 用于更新 view model 的状态
extension MailSearchDataCenter: MailSearchResultCellViewModelDelegate {
    func viewModelDidUpdate(threadId thread: String, viewModel: MailSearchResultCellViewModel) {
        delegate?.resultViewModelDidUpdate(threadId: thread, viewModel: viewModel)
    }
}
