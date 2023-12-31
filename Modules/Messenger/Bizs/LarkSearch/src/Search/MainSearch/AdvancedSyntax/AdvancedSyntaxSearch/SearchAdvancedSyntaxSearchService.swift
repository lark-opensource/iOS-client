//
//  SearchAdvancedSyntaxSearchService.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/12/7.
//

import Foundation
import LarkRustClient
import LarkSDKInterface
import LarkAccountInterface
import LarkSearchCore
import RustPB
import ServerPB
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkContainer
import LarkSearchFilter
import LarkMessengerInterface

struct SearchAdvancedSyntaxInput: Equatable {
    let query: String
    let originSearcherInput: SearcherInput
    let match: NSTextCheckingResult
    let uniqueIdentifier: String

    init(query: String, originSearcherInput: SearcherInput, match: NSTextCheckingResult) {
        self.query = query
        self.originSearcherInput = originSearcherInput
        self.match = match
        self.uniqueIdentifier = "\(CACurrentMediaTime())"
    }

    static func == (lhs: SearchAdvancedSyntaxInput, rhs: SearchAdvancedSyntaxInput) -> Bool {
        return lhs.query == rhs.query && lhs.uniqueIdentifier == rhs.uniqueIdentifier && lhs.originSearcherInput == rhs.originSearcherInput
    }
}

struct RequestInfo: Equatable {
    let input: SearchAdvancedSyntaxInput
    let searchType: SearchFilter.AdvancedSyntaxFilterType
    let tab: SearchTab

    public static func == (lhs: RequestInfo, rhs: RequestInfo) -> Bool {
        return lhs.input == rhs.input && lhs.searchType == rhs.searchType && lhs.tab == rhs.tab
    }
}

enum AdvancedSyntaxSearchState {
    case success(requestInfo: RequestInfo, results: [SearchAdvancedSyntaxItem])
    case error(RequestInfo)
}

/*
 服务端没上人群的无query搜索，且是是PC先行需求，已经这么上线了，故：
 1. 无query 搜人 走RustPB: GetClosestChattersRequest
 2. 无query 搜群 走ServerPB: PullClosestChatsRequest
 3. 有query 走通用搜索
    a. 搜人 场景值: .rustScene(.searchChatters)
    b. 搜群 场景值: .searchUserAndGroupChat
 */
final class SearchAdvancedSyntaxSearchService {
    static let logger = Logger.log(SearchAdvancedSyntaxSearchService.self, category: "Search.SearchAdvancedSyntaxSearchService")
    var lastRequestInfo: RequestInfo?
    let userResolver: UserResolver

    private let disposeBag = DisposeBag()

    var searchAPI: SearchAPI? {
        try? userResolver.resolve(assert: SearchAPI.self)
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 搜索结果
    private let searchStateSubject = PublishSubject<AdvancedSyntaxSearchState>()
    var searchState: Observable<AdvancedSyntaxSearchState> {
        return searchStateSubject.asObservable()
    }

    // 搜人 搜群 有query 无query
    func search(_ input: SearchAdvancedSyntaxInput, searchType: SearchFilter.AdvancedSyntaxFilterType, tab: SearchTab) {
        let requestInfo = RequestInfo(input: input, searchType: searchType, tab: tab)
        lastRequestInfo = requestInfo
        if input.query.isEmpty {
            switch searchType {
            case .fromFilter, .withFilter:
                noQuerySearchChatter(requestInfo: requestInfo)
            case .inFilter:
                noQuerySearchChat(requestInfo: requestInfo)
            @unknown default:
                Self.logger.error("【Lark Search】advanced Syntax search unknown type: \(searchType)")
                return
            }
        } else {
            universalSearch(requestInfo: requestInfo)
        }
    }

    private func noQuerySearchChatter(requestInfo: RequestInfo) {
        searchAPI?.getClosestChatters(begin: 0, end: 15)
            .subscribe(onNext: { [weak self] chatterMetas in
                guard let self = self, requestInfo == self.lastRequestInfo else { return }
                Self.logger.info("【Lark Search】advanced Syntax noQuerySearchChatter resultCount: \(chatterMetas.count)")
                let results = chatterMetas.compactMap { SearchChatterPickerItem.chatterMeta($0) }
                self.searchStateSubject.onNext(AdvancedSyntaxSearchState.success(requestInfo: requestInfo, results: results))
            }, onError: { [weak self] error in
                guard let self = self, requestInfo == self.lastRequestInfo else { return }
                self.searchStateSubject.onNext(AdvancedSyntaxSearchState.error(requestInfo))
                Self.logger.error("【Lark Search】advanced Syntax noQuerySearchChatter error: \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func noQuerySearchChat(requestInfo: RequestInfo) {
        searchAPI?.pullClosestChats(begin: 0, end: 15)
            .subscribe(onNext: { [weak self] chatMetas in
                guard let self = self, requestInfo == self.lastRequestInfo else { return }
                Self.logger.info("【Lark Search】advanced Syntax noQuerySearchChat resultCount: \(chatMetas.count)")
                let results = chatMetas.compactMap { self.convertToChatForwardItem(result: $0) }
                self.searchStateSubject.onNext(AdvancedSyntaxSearchState.success(requestInfo: requestInfo, results: results))
            }, onError: { [weak self] error in
                guard let self = self, requestInfo == self.lastRequestInfo else { return }
                self.searchStateSubject.onNext(AdvancedSyntaxSearchState.error(requestInfo))
                Self.logger.error("【Lark Search】advanced Syntax noQuerySearchChat error: \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func universalSearch(requestInfo: RequestInfo) {
        guard let searchSource = makeSearchSource(searchType: requestInfo.searchType) else { return }

        let request = BaseSearchRequest(query: requestInfo.input.query, count: 15)
        searchSource.search(request: request)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self, requestInfo == self.lastRequestInfo else { return }
                guard let responseResults = response.results as? [SearchResultType] else { return }

                //错误拦截
                if let searchError = response.searchError, searchError != .offline {
                    self.searchStateSubject.onNext(AdvancedSyntaxSearchState.error(requestInfo))
                    Self.logger.info("【Lark Search】advanced Syntax universalSearch rust error \(searchError)")
                    return
                }

                let results = responseResults.compactMap { result -> SearchAdvancedSyntaxItem? in
                    switch (requestInfo.searchType, result.type) {
                    case (SearchFilter.AdvancedSyntaxFilterType.fromFilter, Search.Types.chatter):
                        return SearchChatterPickerItem.searchResultType(result)
                    case (SearchFilter.AdvancedSyntaxFilterType.withFilter, Search.Types.chatter):
                        return SearchChatterPickerItem.searchResultType(result)
                    case (SearchFilter.AdvancedSyntaxFilterType.inFilter, Search.Types.chat):
                        return self.convertToChatForwardItem(result: result)
                    case (SearchFilter.AdvancedSyntaxFilterType.inFilter, Search.Types.chatter):
                        return self.convertToChatForwardItem(result: result)
                    default:
                        break
                    }
                    return nil
                }
                Self.logger.info("【Lark Search】advanced Syntax universalSearch resultCount: \(results.count)")
                self.searchStateSubject.onNext(AdvancedSyntaxSearchState.success(requestInfo: requestInfo, results: results))
            }, onError: { [weak self] (error) in
                guard let self = self, requestInfo == self.lastRequestInfo else { return }
                self.searchStateSubject.onNext(AdvancedSyntaxSearchState.error(requestInfo))
                Self.logger.error("【Lark Search】advanced Syntax universalSearch error: \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func makeSearchSource(searchType: SearchFilter.AdvancedSyntaxFilterType) -> SearchSource? {
        var scene: SearchSceneSection?
        switch searchType {
        case .fromFilter, .withFilter:
            scene = .rustScene(.searchChatters)
        case .inFilter:
            scene = .searchUserAndGroupChat
        @unknown default:
            Self.logger.error("【Lark Search】advanced Syntax search unknown type: \(searchType)")
            return nil
        }
        guard let scene = scene else { return nil }
        let sourceMaker = RustSearchSourceMaker(resolver: userResolver, scene: scene)
        let searchSource = sourceMaker.makeAndReturnProtocol()
        return searchSource
    }
}

extension SearchAdvancedSyntaxSearchService {
    private func convertToChatForwardItem(result: Any) -> ForwardItem? {
        if let searchResultType = result as? SearchResultType {
            switch searchResultType.meta {
            case .chat(let chat):
                var item = ForwardItem(avatarKey: searchResultType.avatarKey,
                                       name: searchResultType.title.string,
                                       subtitle: searchResultType.summary.string,
                                       description: "",
                                       descriptionType: .onDefault,
                                       localizeName: searchResultType.title.string,
                                       id: chat.id,
                                       chatId: chat.id,
                                       type: .chat,
                                       isCrossTenant: chat.isCrossTenant,
                                       isCrossWithKa: chat.isCrossWithKa,
                                       isCrypto: chat.isCrypto,
                                       isThread: chat.chatMode == .threadV2 || chat.chatMode == .thread,
                                       isPrivate: chat.isShield,
                                       channelID: nil,
                                       doNotDisturbEndTime: 0,
                                       hasInvitePermission: true,
                                       userTypeObservable: nil,
                                       enableThreadMiniIcon: false,
                                       isOfficialOncall: chat.isOfficialOncall,
                                       tags: searchResultType.tags,
                                       attributedTitle: searchResultType.title,
                                       attributedSubtitle: searchResultType.summary,
                                       customStatus: nil,
                                       wikiSpaceType: nil,
                                       isShardFolder: nil,
                                       tagData: chat.relationTag.toBasicTagData(),
                                       imageURLStr: nil)
                item.isUserCountVisible = chat.isUserCountVisible
                item.chatUserCount = chat.userCountWithBackup
                return item
            case .chatter(let chatter):
                let userService = try? userResolver.resolve(type: PassportUserService.self)
                let type = ForwardItemType(rawValue: chatter.type.rawValue) ?? .unknown
                var isCrossTenant: Bool = false
                if type == .myAi && chatter.tenantID.isEmpty {
                    isCrossTenant = false
                } else {
                    isCrossTenant = chatter.tenantID != (userService?.userTenant.tenantID ?? "")
                }
                let searchActionType: SearchActionType = .createP2PChat
                var forwardSearchDeniedReason: SearchDeniedReason = .unknownReason
                // 有deniedReason直接判断deniedReason，没有的情况下判断deniedPermissions
                if let searchDeniedReason = chatter.deniedReason[Int32(searchActionType.rawValue)] {
                    forwardSearchDeniedReason = searchDeniedReason
                } else if !chatter.deniedPermissions.isEmpty {
                    forwardSearchDeniedReason = .sameTenantDeny
                }
                let hasInvitePermission = !(forwardSearchDeniedReason == .sameTenantDeny || forwardSearchDeniedReason == .blocked)
                var item = ForwardItem(avatarKey: searchResultType.avatarKey,
                                       name: searchResultType.title.string,
                                       subtitle: searchResultType.summary.string,
                                       description: chatter.description_p,
                                       descriptionType: chatter.descriptionFlag,
                                       localizeName: searchResultType.title.string,
                                       id: chatter.id,
                                       chatId: chatter.p2PChatID,
                                       type: type,
                                       isCrossTenant: isCrossTenant,
                                       isCrossWithKa: false,
                                       isCrypto: false,
                                       isThread: false,
                                       isPrivate: false,
                                       channelID: nil,
                                       doNotDisturbEndTime: chatter.doNotDisturbEndTime,
                                       hasInvitePermission: hasInvitePermission,
                                       userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                                       enableThreadMiniIcon: false,
                                       isOfficialOncall: false,
                                       tags: searchResultType.tags,
                                       attributedTitle: searchResultType.title,
                                       attributedSubtitle: searchResultType.summary,
                                       customStatus: chatter.customStatus.topActive,
                                       tagData: chatter.relationTag.toBasicTagData())
                item.deniedReasons = Array(chatter.deniedReason.values)
                return item
            default:
                return nil
            }
        } else if let chatMeta = result as? ServerPB_Graph_ChatMeta {
            let item = ForwardItem(avatarKey: chatMeta.avatarKey,
                                   name: chatMeta.title,
                                   subtitle: "",
                                   description: "",
                                   descriptionType: .onDefault,
                                   localizeName: chatMeta.title,
                                   id: chatMeta.id,
                                   chatId: chatMeta.id,
                                   type: .chat,
                                   isCrossTenant: false,
                                   isCrypto: false,
                                   isThread: false,
                                   doNotDisturbEndTime: 0,
                                   hasInvitePermission: true,
                                   userTypeObservable: nil,
                                   enableThreadMiniIcon: false,
                                   isOfficialOncall: false)
            return item
        }
        return nil
    }
}

extension ForwardItem: SearchAdvancedSyntaxItem { }

extension SearchChatterPickerItem: SearchAdvancedSyntaxItem { }
