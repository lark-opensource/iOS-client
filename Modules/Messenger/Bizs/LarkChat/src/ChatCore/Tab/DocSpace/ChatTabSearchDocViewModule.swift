//
//  ChatTabSearchDocViewModule.swift
//  LarkChat
//
//  Created by Zigeng on 2022/5/7.
//

import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkContainer

final class ChatTabSearchDocViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatTabSearchDocViewModel.self, category: "ChatTabSearchDocViewModel")
    private let chatId: String
    private let searchAPI: SearchAPI
    private let chatAPI: ChatAPI
    private let router: ChatTabSearchDocRouter
    private let stateSubject = BehaviorRelay<ChatTabSearchDocState>(value: .searching)
    var stateObservable: Observable<ChatTabSearchDocState> {
        return stateSubject.asObservable().observeOn(MainScheduler.instance)
    }

    private let countPerRequest: Int32 = 15
    private(set) var currentSearchData: ChatTabSearchDocData?
    var lastSearchQuery: String?
    var requestOffset: Int32 = 0
    private var currentRequestID: UInt16 = 0
    private var requestToken: Disposable? {
        didSet { oldValue?.dispose() }
    }
    private var moreToken: Any? /// 用于加载更多用

    init(userResolver: UserResolver, chatId: String, router: ChatTabSearchDocRouter) throws {
        self.userResolver = userResolver
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.searchAPI = try userResolver.resolve(assert: SearchAPI.self)
        self.chatId = chatId
        self.router = router
    }

    func search(query: String) {
        lastSearchQuery = query
        currentSearchData = ChatTabSearchDocData(
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
            scene: .rustScene(.searchDoc),
            begin: begin,
            end: end,
            moreToken: moreToken,
            chatID: chatId,
            needSearchOuterTenant: true,
            authPermissions: []
        )
        requestToken = ob.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, currentRequestID] (callBack) in
            guard let self = self, self.currentRequestID == currentRequestID, self.userResolver.valid else { return }

            self.moreToken = callBack.moreToken
            let cellViewModels = callBack.results.compactMap { (searchResult) in
                return try? ChatTabSearchDocCellViewModel(
                    userResolver: self.userResolver,
                    chatId: self.chatId,
                    data: searchResult,
                    router: self.router
                )
            }
            self.preloadDocs(cellViewModels)
            let preVMs = self.currentSearchData?.cellViewModels ?? []
            let newVMs = preVMs + cellViewModels
            if newVMs.isEmpty {
                if query.isEmpty {
                    self.stateSubject.accept(.placeHolder)
                } else {
                    self.stateSubject.accept(.noResult(query))
                }
            } else {
                let data = ChatTabSearchDocData(
                    searchQuery: query,
                    cellViewModels: newVMs,
                    hasMore: callBack.hasMore
                )
                self.currentSearchData = data
                self.stateSubject.accept(.result(data, query))
            }
            self.requestOffset += (end - begin)
            }, onError: { [weak self, currentRequestID] _ in
                guard let self = self, self.currentRequestID == currentRequestID else { return }
                let isLoadMore = !(self.currentSearchData?.cellViewModels.isEmpty ?? true)
                self.stateSubject.accept(.searchFail(query, isLoadMore))
            })
    }

    private func preloadDocs(_ cellDatas: [ChatTabSearchDocCellViewModel]) {
        cellDatas.forEach { (cellData) in
            cellData.preloadDocs()
        }
    }
}

struct ChatTabSearchDocData {
    let searchQuery: String
    let cellViewModels: [ChatTabSearchDocCellViewModel]
    let hasMore: Bool
}

enum ChatTabSearchDocState {
    case placeHolder
    case searching
    case result(ChatTabSearchDocData, String)
    case noResult(String)
    case searchFail(String, Bool)
}
