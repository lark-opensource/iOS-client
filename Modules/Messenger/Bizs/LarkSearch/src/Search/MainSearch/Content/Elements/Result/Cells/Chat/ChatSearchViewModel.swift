//
//  ChatSearchViewModel.swift
//  Lark
//
//  Created by ChalrieSu on 02/04/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import UIKit
import LarkModel
import LarkUIKit
import LarkTag
import RxSwift
import RxRelay
import LarkCore
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import LarkSceneManager
import LarkSearchCore
import LarkContainer
import LarkTab

final class ChatSearchViewModel: SearchCellViewModel, UnreadState, UserResolverWrapper {
    static let logger = Logger.log(ChatSearchViewModel.self, category: "Module.IM.Search")

    let router: SearchRouter
    private let chatAPI: ChatAPI
    private let context: SearchViewModelContext
    private let disposeBag = DisposeBag()
    private let currentChatterId: String
    let searchResult: SearchResultType
    let enableThreadMiniIcon: Bool
    let enableDocCustomAvatar: Bool
    var readed = BehaviorRelay(value: false)

    let userResolver: UserResolver
    var unreadCount: Observable<Int> {
        readed.map { [searchResult] in $0 ? 0 : Self.unreadCount(for: searchResult) }
    }

    var searchClickInfo: String {
        var type = ""
        if case let .chat(chatMeta) = searchResult.meta {
            if chatMeta.isCrypto {
                type = "secret_group_chat"
            } else {
                type = "group"
            }
        }
        return type
    }

    var resultTypeInfo: String {
        return "groups"
    }

    init(userResolver: UserResolver,
         searchResult: SearchResultType,
         currentChatterId: String,
         chatAPI: ChatAPI,
         context: SearchViewModelContext,
         enableDocCustomAvatar: Bool,
         enableThreadMiniIcon: Bool) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.currentChatterId = currentChatterId
        self.chatAPI = chatAPI
        self.router = context.router
        self.context = context
        self.enableDocCustomAvatar = enableDocCustomAvatar
        self.enableThreadMiniIcon = enableThreadMiniIcon
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        readed.accept(true)
        switch searchResult.meta {
        case .chat(let chatMeta):
            chatAPI.fetchChat(by: chatMeta.id, forceRemote: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chat in
                    guard let self = self else { return }
                    if let chat = chat {
                        //cctodo：这是什么逻辑是否需要兼容
                        if chatMeta.isPublicV2, !chatMeta.isMember {
                            let errorBlock: Handler = { _, res in
                                if let err = res.error {
                                    ChatSearchViewModel.logger.error("[LarkSearch] chat search result jump to join group error",
                                                                     additionalData: ["chatId": chat.id],
                                                                     error: err)
                                } else {
                                    ChatSearchViewModel.logger.info("[LarkSearch] chat search result jump to join group success",
                                                                     additionalData: ["chatId": chat.id])
                                }
                            }
                            let body = PreviewChatCardWithChatBody(chat: chat, isFromSearch: true)
                            self.navigator.pushOrShowDetail(body: body, from: vc) {
                                errorBlock($0, $1)
                            }
                            let sessionId = self.context.clickInfo?().sessionId
                            let query = self.context.clickInfo?().query ?? ""
                            let searchLocation = self.context.clickInfo?().searchLocation ?? "none"
                            let scenceType = self.context.clickInfo?().sceneType ?? ""
                            let imprId = self.context.clickInfo?().imprId ?? ""
                            let filters = self.context.clickInfo?().filters ?? []
                            var sortType: String?
                            for filter in filters {
                                if case let .groupSortType(type) = filter {
                                    sortType = type.trackingRepresentation
                                }
                            }
                            var isCache: Bool?
                            if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
                                isCache = service.currentIsCacheVC()
                            }
                            SearchTrackUtil.trackSearchProfileClick(userId: chatMeta.id,
                                                                    searchLocation: searchLocation,
                                                                    query: query,
                                                                    resultType: "groups",
                                                                    sceneType: scenceType,
                                                                    sessionId: sessionId,
                                                                    imprId: imprId,
                                                                    filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                                                    bid: self.searchResult.bid,
                                                                    entityType: self.searchResult.entityType,
                                                                    sortBy: sortType,
                                                                    isCache: isCache)
                        } else {
                            var searchOuterService: SearchOuterService? { try? self.userResolver.resolve(assert: SearchOuterService.self) }
                            if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
                                self.userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: false) { [weak self] _ in
                                    guard let self = self else { return }
                                    guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                                    self.router.gotoChat(withChat: chat, showNormalBack: false, fromVC: topVC)
                                }
                            } else {
                                self.router.gotoChat(withChat: chat, showNormalBack: false, fromVC: vc)
                            }
                        }
                    } else {
                        ChatSearchViewModel.logger.error("[LarkSearch] 点击群组，未找到本地chat", additionalData: [
                            "chatId": chatMeta.id
                            ])
                    }
                })
                .disposed(by: disposeBag)
            return searchResult
        default:
            return nil
        }
    }

    func supportDragScene() -> Scene? {
        switch searchResult.meta {
        case .chat(let chatMeta):
            if let chat = chatAPI.getLocalChat(by: chatMeta.id) {
                if chatMeta.isPublicV2, !chatMeta.isMember {
                    return nil
                } else {
                    var windowType: String = "group"
                    if chat.isMeeting {
                        windowType = "event_group"
                    } else if !chat.oncallId.isEmpty {
                        windowType = "help_desk"
                    }
                    let scene = LarkSceneManager.Scene(
                        key: "Chat",
                        id: chat.id,
                        title: chat.displayName,
                        userInfo: [:],
                        windowType: windowType,
                        createWay: "drag")
                    return scene
                }
            } else {
                ChatSearchViewModel.logger.error("[LarkSearch] 拖拽群组，未找到本地chat", additionalData: [
                    "chatId": chatMeta.id
                    ])
            }
            return nil
        default:
            return nil
        }
    }

    func supprtPadStyle() -> Bool {
        if !UIDevice.btd_isPadDevice() {
            return false
        }
        if SearchTab.main == context.tab {
            return false
        }
        return isPadFullScreenStatus(resolver: userResolver)
    }
}
