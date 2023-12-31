//
//  RustSearchAPI.swift
//  Lark
//
//  Created by Sylar on 2017/11/9.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkModel
import LarkSDKInterface
import LarkRustClient
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer
import LarkMessengerInterface

public final class RustSearchAPI: SearchAPI, UserResolverWrapper {
    let client: RustService
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    public let userResolver: UserResolver
    public init(userResolver: UserResolver, client: RustService) {
        self.userResolver = userResolver
        self.client = client
    }

    public func putSearch(feedbacks: [SearchFeedback],
                   searchText: String,
                   scene: SearchScene,
                   searchSession: String?,
                   imprID: String?) -> Observable<Void> {

        var request = RustPB.Search_V1_SearchFeedbackRequest()
        request.query = searchText
        request.feedbacks = feedbacks
        var reqScene = RustPB.Search_V1_Scene()
        reqScene.type = scene
        if let searchSession = searchSession {
            request.searchSession = searchSession
        }
        if let imprID = imprID {
            request.imprID = imprID
        }

        return client.sendAsyncRequest(request).map { _ in }
    }

    public func universalSearch(
        query: String,
        scene: SearchSceneSection,
        begin: Int32,
        end: Int32,
        moreToken: Any?,
        filter: SearchFilterParam?,
        needSearchOuterTenant: Bool,
        authPermissions: [RustPB.Basic_V1_Auth_ActionType]
    ) -> Observable<SearchCallBack> {
        var sourceMaker = RustSearchSourceMaker(resolver: self.userResolver, scene: scene)
        sourceMaker.authPermissions = authPermissions
        sourceMaker.needSearchOuterTenant = needSearchOuterTenant
        sourceMaker.wikiNeedOwner = true
        let source = sourceMaker.makeAndReturnProtocol()
        if let filterParam = filter {
            let ob1 = chatAPI?.fetchChats(by: filterParam.chatIds, forceRemote: false) ?? .empty()
            let ob2 = chatterAPI?.getChatters(ids: filterParam.messageCreatorIds
                                              + filterParam.docCreatorIds
                                              + filterParam.chatFilterParam.chatMemberIds) ?? .empty()
            return Observable.zip(ob1, ob2)
                .flatMapLatest({ (chatMap, chatterMap) -> Observable<SearchCallBack> in
                    let request = BaseSearchRequest(query: query,
                                                    filters: filterParam.convert(chatMap: chatMap, chatterMap: chatterMap),
                                                    count: Int(end - begin),
                                                    moreToken: begin == 0 ? nil : moreToken,
                                                    context: SearchRequestContext())
                    return source.search(request: request)
                        .map { (response) -> SearchCallBack in
                            return CommonSearchCallBack(
                                searchScene: scene,
                                hasMore: response.hasMore,
                                results: response.results as! [SearchResultType], // swiftlint:disable:this all
                                isRemote: true,
                                imprID: response.context[SearchResponseImprID.self],
                                contextID: response.context[SearchResponseContextID.self],
                                moreToken: response.moreToken
                            )
                        }.catchError { _ in .empty() }
                })
        } else {
            let request = BaseSearchRequest(query: query,
                                            filters: [],
                                            count: Int(end - begin),
                                            moreToken: begin == 0 ? nil : moreToken,
                                            context: SearchRequestContext())
            return source.search(request: request)
                .map { (response) -> SearchCallBack in
                    return CommonSearchCallBack(
                        searchScene: scene,
                        hasMore: response.hasMore,
                        results: response.results as! [SearchResultType], // swiftlint:disable:this all
                        isRemote: true,
                        imprID: response.context[SearchResponseImprID.self],
                        contextID: response.context[SearchResponseContextID.self],
                        moreToken: response.moreToken
                    )
                }.catchError { _ in .empty() }
        }
    }

    public func universalSearch(
        query: String,
        scene: SearchSceneSection,
        begin: Int32,
        end: Int32,
        moreToken: Any?,
        chatID: String?,
        needSearchOuterTenant: Bool,
        authPermissions: [RustPB.Basic_V1_Auth_ActionType]
    ) -> Observable<SearchCallBack> {
        var sourceMaker = RustSearchSourceMaker(resolver: self.userResolver, scene: scene)
        sourceMaker.authPermissions = authPermissions
        sourceMaker.needSearchOuterTenant = needSearchOuterTenant
        sourceMaker.wikiNeedOwner = true
        sourceMaker.chatID = chatID
        let source = sourceMaker.makeAndReturnProtocol()
        let request = BaseSearchRequest(query: query,
                                        filters: [],
                                        count: Int(end - begin),
                                        moreToken: begin == 0 ? nil : moreToken,
                                        context: SearchRequestContext())
        return source.search(request: request)
            .map { (response) -> SearchCallBack in
                return CommonSearchCallBack(
                    searchScene: scene,
                    hasMore: response.hasMore,
                    results: response.results as! [SearchResultType], // swiftlint:disable:this all
                    isRemote: true,
                    imprID: response.context[SearchResponseImprID.self],
                    contextID: response.context[SearchResponseContextID.self],
                    moreToken: response.moreToken
                )
            }.catchError { _ in .empty() }
    }

    public func universalSearch(
        query: String,
        scene: SearchSceneSection,
        moreToken: Any?,
        searchParam: UniversalSearchParam,
        authPermissions: [RustPB.Basic_V1_Auth_ActionType]
    ) -> Observable<SearchCallBack> {
        var sourceMaker = RustSearchSourceMaker(resolver: self.userResolver, scene: scene)
        sourceMaker.authPermissions = authPermissions
        sourceMaker.needSearchOuterTenant = searchParam.needSearchOuterTenant
        sourceMaker.chatID = searchParam.chatID
        sourceMaker.externalID = searchParam.externalID
        sourceMaker.needSearchOuterTenant = searchParam.needSearchOuterTenant
        sourceMaker.doNotSearchResignedUser = searchParam.doNotSearchResignedUser
        sourceMaker.inChatID = searchParam.inChatID
        sourceMaker.chatFilterMode = searchParam.chatFilterMode
        sourceMaker.includeMeetingGroup = searchParam.includeMeetingGroup

        sourceMaker.includeChat = searchParam.includeChat
        sourceMaker.includeDepartment = searchParam.includeDepartment
        sourceMaker.includeUserGroup = searchParam.includeUserGroup
        sourceMaker.includeChatter = searchParam.includeChatter
        sourceMaker.includeBot = searchParam.includeBot
        sourceMaker.includeThread = searchParam.includeThread
        sourceMaker.includeMailContact = searchParam.includeMailContact
        sourceMaker.includeChatForAddChatter = searchParam.includeChatForAddChatter
        sourceMaker.includeDepartmentForAddChatter = searchParam.includeDepartmentForAddChatter
        sourceMaker.includeOuterGroupForChat = searchParam.includeOuterGroupForChat
        sourceMaker.includeShieldP2PChat = searchParam.includeShieldP2PChat
        sourceMaker.includeShieldGroup = searchParam.includeShieldGroup
        sourceMaker.excludeUntalkedChatterBot = searchParam.excludeUntalkedChatterBot
        sourceMaker.wikiNeedOwner = searchParam.wikiNeedOwner
        sourceMaker.excludeOuterContact = searchParam.excludeOuterContact
        sourceMaker.chatID = searchParam.chatID
        sourceMaker.incluedOuterChat = searchParam.incluedOuterChat
        sourceMaker.includeCrypto = searchParam.includeCrypto
        let source = sourceMaker.makeAndReturnProtocol()
        let defaultCount = 15
        let request = BaseSearchRequest(query: query,
                                        filters: [],
                                        count: defaultCount, // 其实这个没用，后端默认返回 15
                                        moreToken: moreToken,
                                        context: SearchRequestContext())
        return source.search(request: request)
            .map { (response) -> SearchCallBack in
                return CommonSearchCallBack(
                    searchScene: scene,
                    hasMore: response.hasMore,
                    results: response.results as! [SearchResultType], // swiftlint:disable:this all
                    isRemote: true,
                    imprID: response.context[SearchResponseImprID.self],
                    contextID: response.context[SearchResponseContextID.self],
                    moreToken: response.moreToken
                )
            }
    }

    public func universalRecommendFeeds(request: ServerPB_Usearch_PullDocFeedCardsRequest) -> Observable<[SearchResultType]> {
        return client.sendPassThroughAsyncRequest(request, serCommand: .noQueryRecommendFeedCards)
            .map { (response: ServerPB_Usearch_PullDocFeedCardsResponse) -> [SearchResultType] in
                let searchResults = response.result
                return searchResults.map {
                    Search.UniversalRecommendResult(base: $0, contextID: nil)
                }
            }
    }

    public func deleteAllSearchInfos() -> Observable<Search_V1_DeleteAllSearchInfosHistoryResponse> {
        let request = DeleteAllSearchInfosHistoryRequest()
        return client.sendAsyncRequest(request)
    }

    public func getClosestChatters(begin: Int32, end: Int32) -> Observable<[ChatterMeta]> {
        var request = Tool_V1_GetClosestChattersRequest()
        request.begin = begin
        request.end = end
        return client.sendAsyncRequest(request)
            .map { (response: Tool_V1_GetClosestChattersResponse) -> [ChatterMeta] in
                response.chatters
            }
    }

    public func pullClosestChats(begin: Int32, end: Int32) -> Observable<[ServerPB_Graph_ChatMeta]> {
        var request = ServerPB_Graph_PullClosestChatsRequest()
        request.begin = begin
        request.end = end
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullClosestChats)
            .map { (response: ServerPB_Graph_PullClosestChatsResponse) -> [ServerPB_Graph_ChatMeta] in
                response.chats
            }
    }

    /// 分词
    public func segmentText(text: String) -> Observable<Search_V1_SegmentTextResponse> {
        var request = Search_V1_SegmentTextRequest()
        request.texts = [text]
        return client.sendAsyncRequest(request)
    }

    public func fetchRecentForwardItems(includeGroupChat: Bool,
                                        includeP2PChat: Bool,
                                        includeThreadChat: Bool,
                                        includeOuterChat: Bool,
                                        includeSelf: Bool,
                                        includeMyAi: Bool,
                                        strategy: Basic_V1_SyncDataStrategy) -> Observable<[Feed_V1_GetRecentTransmitTargetsResponse.RecentTransmitTarget]> {
        var request = Feed_V1_GetRecentTransmitTargetsRequest()
        request.filterGroupChat = !includeGroupChat
        request.filterMyself = !includeSelf
        request.filterP2PChat = !includeP2PChat
        request.filterThreadChat = !includeThreadChat
        request.filterCrossTenantChat = !includeOuterChat
        request.includeMyAi = includeMyAi
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request)
            .map { (res: Feed_V1_GetRecentTransmitTargetsResponse) -> [Feed_V1_GetRecentTransmitTargetsResponse.RecentTransmitTarget] in
                return res.targets
            }
    }
}

public struct SectionSearchCallBack: SearchCallBack {
    public var searchScene: SearchSceneSection
    public var hasMore: Bool
    public var results: [SearchResultType]
    public var isRemote: Bool
    public let headerInfo: SearchSectionHeader
    public let footerInfo: SearchSectionFooter
    public var imprID: String?
    public var contextID: String?
    public var moreToken: Any?
    public var extra: String?
    public var isSpotlight: Bool = false

    public init(searchScene: SearchSceneSection,
                hasMore: Bool,
                results: [SearchResultType],
                isRemote: Bool,
                headerInfo: SearchSectionHeader,
                footerInfo: SearchSectionFooter,
                imprID: String? = nil,
                contextID: String? = nil,
                moreToken: Any? = nil,
                extra: String? = nil,
                isSpotlight: Bool = false) {
        self.searchScene = searchScene
        self.hasMore = hasMore
        self.results = results
        self.isRemote = isRemote
        self.headerInfo = headerInfo
        self.footerInfo = footerInfo
        self.imprID = imprID
        self.contextID = contextID
        self.moreToken = moreToken
        self.extra = extra
        self.isSpotlight = isSpotlight
    }
}

public struct CommonSearchCallBack: SearchCallBack {
    public var searchScene: SearchSceneSection
    public var hasMore: Bool
    public var results: [SearchResultType]
    public var isRemote: Bool
    public var imprID: String?
    public var contextID: String?
    public var moreToken: Any?
    public var extra: String?
    public var isSpotlight: Bool = false
    public var errorInfo: Search_V2_SearchCommonResponseHeader.ErrorInfo?

    public init(searchScene: SearchSceneSection,
                hasMore: Bool,
                results: [SearchResultType],
                isRemote: Bool,
                imprID: String? = nil,
                contextID: String? = nil,
                moreToken: Any?,
                extra: String? = nil,
                isSpotlight: Bool = false) {
        self.searchScene = searchScene
        self.hasMore = hasMore
        self.results = results
        self.isRemote = isRemote
        self.imprID = imprID
        self.contextID = contextID
        self.moreToken = moreToken
        self.extra = extra
        self.isSpotlight = isSpotlight
    }
    public init(_ from: SearchCallBack) {
        self.searchScene = from.searchScene
        self.hasMore = from.hasMore
        self.results = from.results
        self.isRemote = from.isRemote
        self.imprID = from.imprID
        self.contextID = from.contextID
        self.moreToken = from.moreToken
        self.extra = from.extra
        self.isSpotlight = from.isSpotlight
    }
    public static func empty(scene: SearchSceneSection) -> CommonSearchCallBack {
        .init(searchScene: scene, hasMore: false, results: [], isRemote: true, moreToken: nil)
    }
}

protocol RustSearchResponseV1 {
    var results: [SearchResult] { get }
    var hasMore_p: Bool { get }
    var chatters: [String: SearchChatterMeta] { get }
    var chats: [String: SearchChatMeta] { get }
    var messages: [String: SearchMessageMeta] { get }
    var docs: [String: SearchDocMeta] { get }
    var threads: [String: SearchThreadMeta] { get }
    var boxs: [String: SearchBoxMeta] { get }
    var oncalls: [String: SearchOncallMeta] { get }
    var docFeeds: [String: SearchDocFeedMeta] { get }
    var cryptoP2PChats: [String: SearchCryptoP2PChatMeta] { get }
    var openApps: [String: SearchOpenAppMeta] { get }
    var links: [String: SearchLinkMeta] { get }
    var externals: [String: SearchExternalMeta] { get }
    var wikis: [String: SearchWikiMeta] { get }
    var mails: [String: SearchMailMeta] { get }
    var slashCommands: [String: Search_Slash_V1_SlashCommandMeta] { get }
}
extension RustSearchResponseV1 {
    var docs: [String: SearchDocMeta] { [:] }
    var boxs: [String: SearchBoxMeta] { [:] }
    var oncalls: [String: SearchOncallMeta] { [:] }
    var docFeeds: [String: SearchDocFeedMeta] { [:] }
    var cryptoP2PChats: [String: SearchCryptoP2PChatMeta] { [:] }
    var openApps: [String: SearchOpenAppMeta] { [:] }
    var links: [String: SearchLinkMeta] { [:] }
    var externals: [String: SearchExternalMeta] { [:] }
    var wikis: [String: SearchWikiMeta] { [:] }
    var mails: [String: SearchMailMeta] { [:] }
    var slashCommands: [String: Search_Slash_V1_SlashCommandMeta] { [:] }
}
extension RustPB.Search_V1_IntegrationSearchResponse: RustSearchResponseV1 { }
extension RustPB.Search_V1_LocalIntegrationSearchResponse: RustSearchResponseV1 {}
extension Search_V2_UniformLocalSearchResponse: RustSearchResponseV1 {}

typealias SearchDocFeedMeta = RustPB.Search_V1_SearchDocFeedMeta
typealias SearchExternalMeta = RustPB.Search_V1_SearchExternalMeta
typealias IntegrationSearchRequest = RustPB.Search_V1_IntegrationSearchRequest
typealias PutSearchQueryHistoryRequest = ServerPB_Usearch_PutSearchQueryHistoryRequest
typealias PutSearchQueryHistoryResponse = ServerPB_Usearch_PutSearchQueryHistoryResponse
typealias GetLocalSearchInfoHistoryRequest = RustPB.Search_V1_GetLocalSearchInfoHistoryRequest
typealias DeleteAllSearchInfosHistoryRequest = RustPB.Search_V1_DeleteAllSearchInfosHistoryRequest
