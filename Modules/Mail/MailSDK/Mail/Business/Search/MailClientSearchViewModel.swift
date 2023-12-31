//
//  MailClientSearchViewModel.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/4/7.
//

import Foundation
import RxSwift
import Reachability
import RxRelay
import RustPB
import Homeric

enum MailClientSearchResultState {
    case loading
    case localResult(dataArray: [MailSearchCallBack])
    case localFail(reason: String)
    case localNoResult(searchText: String)
    case remoteResult(dataArray: [MailSearchCallBack])
    case remoteFail(reason: String)
    case remoteNoResult
}

struct MailClientSearchParma {
    var keyword: String
    var begin: Int
    var strategy: MailSearchSearchStrategy
    var loadMore: Bool
    var hasMore: Bool
    var hasTrashOrSpam: Bool
    var fromLabel: String
}

class MailClientSearchDataCenter: MailSearchViewModel {
    // MARK: ViewModel interface
    var state: BehaviorRelay<MailSearchViewControllerState>
    var commonSession = ""
    var refreshList: BehaviorRelay<Bool>
    weak var delegate: MailSearchDataCenterDelegate?

    // MARK: property
    let searchSession = MailSearchSession()
    var lastSearchText: String = ""
    var scene: MailSearchScene = .inMailTab
    private var disposeBag = DisposeBag()
    var hasMore: Bool = true
    var remoteHasMore: Bool = true
    var nextBegin: Int = 0
    var offset: Int = 1
    var strategy: MailSearchSearchStrategy = .local
    var sectionData: [MailSearchSectionData]
    var clientRequestMap = [String: MailClientSearchParma]() // Cache已发送请求, 接rust push后重新发起
    var debounceInterval: Int = -1
    private let pushDisposeBag = DisposeBag()
    var offlineSearch: Bool = false
    let offlineSearchFG = FeatureManager.open(FeatureKey(fgKey: .offlineSearch, openInMailClient: true))
    private var lastConnection: Reachability.Connection = .wifi

    init() {
        state = BehaviorRelay(value: .empty)
        refreshList = BehaviorRelay(value: false)
        sectionData = [MailSearchSectionData(searchResultItems: []),
                       MailSearchSectionData(searchResultItems: [])] // 第一个是local
        MailCommonDataMananger
            .shared
            .mixSearchPushChange
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] change in
                self?.handleMixSearchPush(change)
            }).disposed(by: pushDisposeBag)
    }

    func updateItem(_ indexPath: IndexPath, item: MailSearchCallBack) {
        sectionData[indexPath.section].searchResultItems[indexPath.row] = item
    }

    func setResultItems(_ items: [MailSearchCallBack]) {
        sectionData[0].searchResultItems = items
    }
    func getRemoteResultItems() -> [MailSearchCallBack] {
        guard sectionData.count > 1 else { return [] }
        return sectionData[1].searchResultItems
    }
    func setRemoteResultItems(_ items: [MailSearchCallBack]) {
        guard sectionData.count > 1 else { return }
        sectionData[1].searchResultItems = items
    }

    func removeAllResultItems() {
        sectionData[0].searchResultItems.removeAll()
        sectionData[1].searchResultItems.removeAll()
    }

    func removeAllRemoteResultItems() {
        sectionData[1].searchResultItems.removeAll()
    }

    func handleMixSearchPush(_ change: MailMixSearchPushChange) {
        let session = change.searchSession
        guard let parma = clientRequestMap[session] else {
            MailLogger.error("[mail_client_search] response receive session: \(session), viewModel not save")
            return
        }
        MailLogger.info("[mail_client_search] handleMixSearchPush status: \(change.state) session: \(session) count: \(change.count) begin: \(change.begin) strategy: \(parma.strategy)")
        switch change.state {
        case .abort, .error:
            guard session == searchSession.clientSession else { return }
            let info = MailSearchInfo(offlineSearch: self.offlineSearch, isLoadMore: parma.loadMore, searchText: parma.keyword, hasMore: parma.hasMore, hasTrashOrSpam: parma.hasTrashOrSpam)
            if parma.strategy == .local {
                self.state.accept(.clientResult(state: .localFail(reason: "MailMixSearchPushChange local error"), info: info))
            } else {
                self.state.accept(.clientResult(state: .remoteFail(reason: "MailMixSearchPushChange remote error"), info: info))
            }
        case .ready:
            clientSearch(keyword: parma.keyword, begin: parma.begin, loadMore: parma.loadMore,
                         strategy: parma.strategy, forceReload: false, debounceInterval: -1, fromLabel: parma.fromLabel)
            //clientRequestMap.removeValue(forKey: session)
        @unknown default:
            MailLogger.error("[mail_client_search] response status: \(change.state) no handler")
        }
    }

    func search(keyword: String, filters: [MailSearchFilter], begin: Int, loadMore: Bool, forceReload: Bool, fromLabel: String) { // 首屏数据保持现有逻辑一直，Saas下是网络数据，三方下是本地搜索
        defer {
            lastSearchText = keyword
        }

        MailLogger.info("[mail_client_search] local search begin: \(begin) loadMore: \(loadMore)")
        strategy = .local
        debounceInterval = -1
        clientSearch(keyword: keyword, begin: begin, loadMore: loadMore, strategy: strategy, forceReload: forceReload, debounceInterval: debounceInterval, fromLabel: fromLabel)
    }

    func clientSearch(keyword: String, begin: Int, loadMore: Bool, strategy: MailSearchSearchStrategy, forceReload: Bool, debounceInterval: Int, fromLabel: String) {
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            disposeBag = DisposeBag()
            state.accept(.history)
            return
        }
        
        if offlineSearchFG {
            if !loadMore, let reach = Reachability() {
                lastConnection = reach.connection
            }
            offlineSearch = lastConnection == .none
        }

        if !loadMore {
            if keyword != lastSearchText {
                nextBegin = 0
                offset = 1
                searchSession.renewClientSession()
            }
            if strategy == .local {
                hasMore = true
            } else {
                remoteHasMore = true
            }
            if forceReload || lastSearchText.isEmpty {
                searchSession.renewClientSession()
                state.accept(.clientResult(state: .loading,
                                           info: MailSearchInfo(offlineSearch: offlineSearch,
                                                                isLoadMore: loadMore,
                                                                searchText: keyword,
                                                                hasMore: false,
                                                                hasTrashOrSpam: false))) // 列表空时的全新搜索。全新搜索展示loading
            }
        }

        self.debounceInterval = debounceInterval
        disposeBag = DisposeBag() // 新垃圾袋，释放掉之前的请求
        let startTime = Int(1000 * Date().timeIntervalSince1970)
        let heightlight = keyword.split(separator: " ").map{ return String($0) }
        let search = Store
            .fetcher?
            .remoteClientSearch(keyword: keyword, searchSession: searchSession.clientSession, begin: Int64(begin), strategy: strategy, debounceInterval: Int64(debounceInterval), fromLabel: fromLabel)
            .observeOn(MainScheduler.instance)
        search?.map {(response) -> (MailRemoteSearchResponse, [MailSearchResultCellViewModel]) in
            return (response, response.vms)
        }.subscribe(onNext: { [weak self] (response, viewModels) in
            guard let `self` = self else { return }
            MailLogger.info("[mail_client_search] clientMixSearch response status: \(response.state) session: \(response.searchSession) nextBegin: \(response.nextBegin) viewModels: \(viewModels.count) containTrashOrSpam: \(response.containTrashOrSpam)")
            if self.searchSession.clientSession.isEmpty {
                self.searchSession.clientSession = response.searchSession
            }
            switch response.state {
            case .pending:
                // stash request, send request again when push
                let parma = MailClientSearchParma(keyword: keyword, begin: begin,
                                                  strategy: strategy, loadMore: loadMore,
                                                  hasMore: response.hasMore,
                                                  hasTrashOrSpam: response.containTrashOrSpam,
                                                  fromLabel: fromLabel)
                self.clientRequestMap.updateValue(parma, forKey: response.searchSession)
            case .abort:
                break
            case .ready:
                let parma = MailClientSearchParma(keyword: keyword, begin: begin,
                                                  strategy: strategy, loadMore: loadMore,
                                                  hasMore: response.hasMore,
                                                  hasTrashOrSpam: response.containTrashOrSpam,
                                                  fromLabel: fromLabel)
                self.clientRequestMap.updateValue(parma, forKey: response.searchSession)
                let strategyShouldFetchAgain: MailSearchSearchStrategy = {
                    if Store.settingData.getCachedCurrentAccount()?.protocol == .exchange {
                        return .local // eas只支持本地搜索
                    } else {
                        return .remote
                    }
                }()
                if FeatureManager.open(.searchTrashSpam, openInMailClient: true),
                   parma.strategy == strategyShouldFetchAgain && !response.hasMore && fromLabel == Mail_LabelId_SEARCH {
                    MailLogger.info("[mail_client_search] remoteClientSearch last req response: \(response.containTrashOrSpam) status: \(response.state) session: \(response.searchSession) nextBegin: \(response.nextBegin) hasMore: \(response.hasMore)")
                    let startTime = Int(1000 * Date().timeIntervalSince1970)
                    let search = Store.fetcher?
                        .remoteClientSearch(keyword: parma.keyword, searchSession: response.searchSession, begin: 0, strategy: strategyShouldFetchAgain, debounceInterval: -1, fromLabel: Mail_LabelId_SEARCH_TRASH_AND_SPAM)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (lastResponse) in
                            guard let `self` = self else { return }
                            MailLogger.info("[mail_client_search] remoteClientSearch last req lastResponse: \(lastResponse.containTrashOrSpam) status: \(lastResponse.state) session: \(lastResponse.searchSession) nextBegin: \(lastResponse.nextBegin) hasMore: \(lastResponse.hasMore)")
                            if response.state == .pending {
                                let parma = MailClientSearchParma(keyword: keyword, begin: begin,
                                                                  strategy: strategy, loadMore: loadMore,
                                                                  hasMore: lastResponse.hasMore,
                                                                  hasTrashOrSpam: lastResponse.containTrashOrSpam,
                                                                  fromLabel: fromLabel)
                                self.clientRequestMap.updateValue(parma, forKey: lastResponse.searchSession)
                            } else if response.state == .ready {
                                var lastResponseInfo = lastResponse
                                lastResponseInfo.containTrashOrSpam = !lastResponse.vms.isEmpty
                                lastResponseInfo.hasMore = response.hasMore
                                self.handlerSearchResponse(response: lastResponseInfo, viewModels: viewModels,
                                                           loadMore: loadMore, keyword: keyword, startTime: startTime)
                            }
                        }, onError: { (error) in
                            MailLogger.error("[mail_client_search] remoteClientSearch error status: \(error)")
                        }).disposed(by: self.disposeBag)
                } else {
                    self.handlerSearchResponse(response: response, viewModels: viewModels,
                                               loadMore: loadMore, keyword: keyword, startTime: startTime)
                }
            @unknown default:
                MailLogger.error("[mail_client_search] response status: \(response.state) no handler")
            }
        }, onError: { [weak self] (error) in
            MailLogger.error("[mail_client_search] error status: \(error)")
            if let `self` = self {
                let info = MailSearchInfo(offlineSearch: self.offlineSearch, isLoadMore: loadMore, searchText: keyword,
                                          hasMore: self.strategy == .local ? self.hasMore : self.remoteHasMore,
                                          hasTrashOrSpam: false)
                if self.strategy == .local {
                    self.state.accept(.clientResult(state: .localFail(reason: error.localizedDescription), info: info))
                } else {
                    self.state.accept(.clientResult(state: .remoteFail(reason: error.localizedDescription), info: info))
                }
            }
        }).disposed(by: disposeBag)
    }

    func searchAbort() {
        MailLogger.info("[mail_client_search] searchAbort session: \(searchSession.clientSession)")
        disposeBag = DisposeBag()
        let startTime = Int(1000 * Date().timeIntervalSince1970)
        let search = Store
            .fetcher?
            .clientMixSearch(keyword: lastSearchText, searchSession: searchSession.clientSession, begin: 0, strategy: .abort, debounceInterval: -1, label_filter: Mail_LabelId_SEARCH)
            .observeOn(MainScheduler.instance)
        search?.map { (response) -> (Email_Client_V1_MailMixedSearchResponse, [MailSearchResultCellViewModel]) in
            return (response, [])
        }.subscribe(onNext: { [weak self] (response, _) in
            guard let `self` = self else { return }
            MailLogger.info("[mail_client_search] searchAbort response status: \(response.state) session: \(response.searchSession) nextBegin: \(response.nextBegin)")
        }, onError: { [weak self] (error) in
            MailLogger.error("[mail_client_search] searchAbort error status: \(error)")
        }).disposed(by: disposeBag)
    }

    func searchRemote(keyword: String, begin: Int, loadMore: Bool, debounceInterval: Int, fromLabel: String) {
        defer {
            lastSearchText = keyword
        }

        MailLogger.info("[mail_client_search] remote search begin: \(begin) loadMore: \(loadMore) debounceInterval: \(debounceInterval)")
        strategy = .remote
        remoteHasMore = true
        clientSearch(keyword: keyword, begin: begin, loadMore: loadMore, strategy: strategy, forceReload: false, debounceInterval: debounceInterval, fromLabel: fromLabel)
    }

    func updateCommonSession(commonSession: String) {
        self.commonSession = commonSession
    }

    func handlerSearchResponse(response: MailRemoteSearchResponse,
                               viewModels: [MailSearchResultCellViewModel],
                               loadMore: Bool,
                               keyword: String,
                               startTime: Int) {
        if response.nextBegin != 0 {
            self.nextBegin = Int(response.nextBegin)
        }
        self.offset += 1
        if strategy == .local {
            self.hasMore = response.hasMore
        } else {
            self.remoteHasMore = response.hasMore
        }
        var info = MailSearchInfo(offlineSearch: self.offlineSearch, isLoadMore: loadMore,
                                  searchText: keyword, hasMore: strategy == .local ? hasMore : remoteHasMore, hasTrashOrSpam: response.containTrashOrSpam)
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
        MailLogger.info("[mail_client_search] searchCallBacks count: \(searchCallBacks.count) loadMore: \(loadMore) hasMore: \(hasMore) remoteHasMore: \(remoteHasMore) strategy: \(strategy) response.hasMore_p: \(response.hasMore) nextBegin: \(self.nextBegin) response.nextBegin: \(response.nextBegin) containTrashOrSpam: \(response.containTrashOrSpam)")
        if searchCallBacks.isEmpty && !response.hasMore {
            if strategy == .remote {
                self.state.accept(.clientResult(state: .remoteNoResult, info: info))
            } else if strategy == .local {
                self.state.accept(.clientResult(state: .localNoResult(searchText: keyword), info: info))
            }
        } else {
            if loadMore {
                sectionData[0].searchResultItems.append(contentsOf: searchCallBacks)
            } else {
                sectionData[0].searchResultItems = searchCallBacks
            }
            if strategy == .remote {
                self.state.accept(.clientResult(state: .remoteResult(dataArray: searchCallBacks), info: info))
            } else if strategy == .local {
                self.state.accept(.clientResult(state: .localResult(dataArray: searchCallBacks), info: info))
            }
        }
        MailTracker.log(event: Homeric.ASL_SEARCH_TIME_DEV,
                        params: ["search_location": "emails",
                                 "search_id": self.searchSession.uuid,
                                 "query_length": keyword.count,
                                 "time": Int(1000 * Date().timeIntervalSince1970) - startTime,
                                 "search_session_id": self.commonSession,
                                 "request_timestamp": String(Int(Date().timeIntervalSince1970)),
                                 "scene_type": "component"])
    }
}

// 用于更新 view model 的状态
extension MailClientSearchDataCenter: MailSearchResultCellViewModelDelegate {
    func viewModelDidUpdate(threadId thread: String, viewModel: MailSearchResultCellViewModel) {
        delegate?.resultViewModelDidUpdate(threadId: thread, viewModel: viewModel)
    }
}
