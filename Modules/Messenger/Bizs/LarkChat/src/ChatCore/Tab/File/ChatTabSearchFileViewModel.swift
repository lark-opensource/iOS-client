//
//  ChatTabSearchFileViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/22.
//
import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkContainer

final class ChatTabSearchFileViewModel {
    static let logger = Logger.log(ChatTabSearchFileViewModel.self, category: "ChatTabSearchFileViewModel")
    private let chatId: String
    private let searchAPI: SearchAPI
    private let chatAPI: ChatAPI
    private let router: ChatTabSearchFileRouter
    private let stateSubject = BehaviorRelay<ChatTabSearchFileState>(value: .searching)
    var stateObservable: Observable<ChatTabSearchFileState> {
        return stateSubject.asObservable().observeOn(MainScheduler.instance)
    }

    private let countPerRequest: Int32 = 15
    private(set) var currentSearchData: ChatTabSearchFileData?
    var lastSearchQuery: String?
    var requestOffset: Int32 = 0
    private var currentRequestID: UInt16 = 0
    private var requestToken: Disposable? {
        didSet { oldValue?.dispose() }
    }
    private var moreToken: Any? /// 用于加载更多用

    let userResolver: UserResolver
    init(userResolver: UserResolver, chatId: String, router: ChatTabSearchFileRouter) throws {
        self.userResolver = userResolver
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.searchAPI = try userResolver.resolve(assert: SearchAPI.self)
        self.chatId = chatId
        self.router = router
    }

    func search(query: String) {
        lastSearchQuery = query
        currentSearchData = ChatTabSearchFileData(
            searchQuery: query,
            cellViewModels: [],
            hasMore: false
        )
        stateSubject.accept(.searching)
        requestOffset = 0
        request(query: query,
                begin: requestOffset,
                end: requestOffset + countPerRequest)
    }

    func loadMore(query: String) {
        request(query: query,
                begin: requestOffset,
                end: requestOffset + countPerRequest)
    }

    private func request(query: String, begin: Int32, end: Int32) {
        assert(Thread.isMainThread, "should occur on main thread!")
        currentRequestID &+= 1
        let ob: Observable<SearchCallBack> = self.searchAPI.universalSearch(
            query: query,
            scene: .rustScene(.searchFileScene),
            begin: begin,
            end: end,
            moreToken: moreToken,
            chatID: chatId,
            needSearchOuterTenant: true,
            authPermissions: []
        )
        requestToken = ob.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, currentRequestID] (callBack) in
            guard let self = self, self.currentRequestID == currentRequestID else { return }

            self.moreToken = callBack.moreToken
            let cellViewModels = callBack.results.map { (searchResult) -> ChatTabSearchFileCellViewModel in
                return ChatTabSearchFileCellViewModel(
                    userResolver: self.userResolver,
                    chatId: self.chatId,
                    data: searchResult,
                    router: self.router
                )
            }
            let preVMs = self.currentSearchData?.cellViewModels ?? []
            let newVMs = preVMs + cellViewModels
            if newVMs.isEmpty {
                if query.isEmpty {
                    self.stateSubject.accept(.placeHolder)
                } else {
                    self.stateSubject.accept(.noResult(query))
                }
            } else {
                let data = ChatTabSearchFileData(
                    searchQuery: query,
                    cellViewModels: newVMs,
                    hasMore: callBack.hasMore
                )
                self.currentSearchData = data
                self.stateSubject.accept(.result(data, query))
            }
            if !query.isEmpty {
                FileTabTracker.FileListClickSearch()
            }
            self.requestOffset += (end - begin)
            }, onError: { [weak self, currentRequestID] _ in
                guard let self = self, self.currentRequestID == currentRequestID else { return }
                let isLoadMore = !(self.currentSearchData?.cellViewModels.isEmpty ?? true)
                self.stateSubject.accept(.searchFail(query, isLoadMore))
            })
    }
}

struct ChatTabSearchFileData {
    let searchQuery: String
    let cellViewModels: [ChatTabSearchFileCellViewModel]
    let hasMore: Bool
}

enum ChatTabSearchFileState {
    case placeHolder
    case searching
    case result(ChatTabSearchFileData, String)
    case noResult(String)
    case searchFail(String, Bool)
}
