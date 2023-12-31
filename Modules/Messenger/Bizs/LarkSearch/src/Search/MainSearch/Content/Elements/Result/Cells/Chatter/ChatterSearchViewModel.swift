//
//  ContactSearchViewModel.swift
//  Lark
//
//  Created by ChalrieSu on 02/04/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkUIKit
import LarkTag
import Swinject
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import LarkAlertController
import LarkSceneManager
import RxRelay
import LarkSearchCore
import LarkContainer
import LarkTab

final class ChatterSearchViewModel: SearchCellViewModel, UnreadState {
    // 点击个人名片页面的回调
    var clickPersonCardButton: ((_ row: Int?, _ chatterId: String) -> Void)?
    // 保存点击个人名片页面的历史记录
    var saveClickPersonCardHistory: ((_ indexPath: IndexPath?, _ chatterSearchViewModel: ChatterSearchViewModel?) -> Void)?
    // 当前所处的行数
    var indexPath: IndexPath?
    // 部门是否应该为折叠状态
    var divisionInFoldStatus: Bool = true
    // 当前tableView宽度
    var tableViewWidth: CGFloat = 0

    static let logger = Logger.log(ChatterSearchViewModel.self, category: "Module.IM.Search")

    private let chatService: ChatService
    private let chatAPI: ChatAPI
    private let feedAPI: FeedAPI
    let router: SearchRouter
    private let context: SearchViewModelContext
    let searchResult: SearchResultType
    let serverNTPTimeService: ServerNTPTimeService

    var searchClickInfo: String {
        var clickTarget = ""
        switch searchResult.meta {
        case .chatter(let chatterMeta):
            if chatterMeta.type == .bot {
                clickTarget = "single_bot"
            } else {
                clickTarget = "single"
            }
        case .cryptoP2PChat:
            clickTarget = "secret_single_chat"
        default:
            break
        }
        return clickTarget
    }

    var resultTypeInfo: String {
        var clickTarget = ""
        switch searchResult.meta {
        case .chatter(let chatterMeta):
            if chatterMeta.type == .bot {
                clickTarget = "single_bot"
            } else if chatterMeta.type == .ai {
                clickTarget = "myai"
            } else {
                clickTarget = "contacts"
            }
        case .cryptoP2PChat:
            clickTarget = "crypto_p2p_chat"
        case .shieldP2PChat:
            clickTarget = "shield_p2p_chat"
        default:
            break
        }
        return clickTarget
    }

    let disposeBag = DisposeBag()
    var readed = BehaviorRelay(value: false)
    var unreadCount: Observable<Int> {
        readed.map { [searchResult] in $0 ? 0 : Self.unreadCount(for: searchResult) }
    }
    private lazy var searchOuterService: SearchOuterService? = {
        let service = try? self.userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         searchResult: SearchResultType,
         chatService: ChatService,
         chatAPI: ChatAPI,
         feedAPI: FeedAPI,
         serverNTPTimeService: ServerNTPTimeService,
         context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.context = context
        self.router = context.router
        self.chatService = chatService
        self.chatAPI = chatAPI
        self.feedAPI = feedAPI
        self.serverNTPTimeService = serverNTPTimeService
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        readed.accept(true)
        switch searchResult.meta {
        case .chatter(let chatterMeta):
            if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
                userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: true) { [weak self] _ in
                    guard let self = self else { return }
                    guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                    self.jumpToChat(chatterMeta: chatterMeta, fromVC: topVC)
                }
            } else {
                jumpToChat(chatterMeta: chatterMeta, fromVC: vc)
            }
            return searchResult
        case .cryptoP2PChat(let meta):
            chatAPI.fetchChat(by: meta.id, forceRemote: false).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chat) in
                    guard let self = self, let chat = chat else {
                        ChatterSearchViewModel.logger.error("[LarkSearch] chat not found when clicking cryptoP2PChat", additionalData: [
                            "chatId": meta.id
                        ])
                        return
                    }
                    self.router.gotoChat(withChat: chat, showNormalBack: false, fromVC: vc)
                }, onError: { _ in
                    ChatterSearchViewModel.logger.error("[LarkSearch] chat not found when clicking cryptoP2PChat", additionalData: [
                        "chatId": meta.id
                    ])
                }).disposed(by: disposeBag)
            return searchResult
        case .shieldP2PChat(let meta):
            chatAPI.fetchChat(by: meta.id, forceRemote: false).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chat) in
                    guard let self = self, let chat = chat else {
                        ChatterSearchViewModel.logger.error("[LarkSearch] chat not found when clicking shieldP2PChat", additionalData: [
                            "chatId": meta.id
                        ])
                        return
                    }
                    self.router.gotoChat(withChat: chat, showNormalBack: false, fromVC: vc)
                }, onError: { _ in
                    ChatterSearchViewModel.logger.error("[LarkSearch] chat not found when clicking shieldP2PChat", additionalData: [
                        "chatId": meta.id
                    ])
                }).disposed(by: disposeBag)
            return searchResult
        default:
            return nil
        }
    }

    private func jumpToChat(chatterMeta: SearchMetaChatterType, fromVC: UIViewController) {
        if chatterMeta.type == .bot {
            // 机器人跳转回话
            self.goToBotChatWith(chatterMeta: chatterMeta, fromVC: fromVC)
        } else if chatterMeta.type == .user {
            // 普通人跳转会话
            self.goToChatWith(chatterID: chatterMeta.id, chatId: chatterMeta.p2PChatID, fromVC: fromVC)
        } else if chatterMeta.type == .ai {
            self.router.gotoMyAI(fromVC: fromVC)
        }
    }

    func supportDragScene() -> Scene? {
        switch searchResult.meta {
        case .chatter(let chatterMeta):
            let windowType = chatterMeta.type == .bot ?
            "bot" : "single"
            let scene = LarkSceneManager.Scene(
                key: "P2pChat",
                id: chatterMeta.id,
                title: searchResult.title.string,
                userInfo: [:],
                windowType: windowType,
                createWay: "drag")
            return scene
        case .cryptoP2PChat(let meta):
            if let chat = chatAPI.getLocalChat(by: meta.id) {
                let scene = LarkSceneManager.Scene(
                    key: "Chat",
                    id: chat.chatterId,
                    title: searchResult.title.string,
                    userInfo: ["chatID": chat.id],
                    windowType: "single",
                    createWay: "drag")
                return scene
            } else {
                ChatterSearchViewModel.logger.error("[LarkSearch] 拖拽密聊，未找到本地chat", additionalData: [
                    "chatId": meta.id
                ])
            }
            return nil
        case .shieldP2PChat(let meta):
            if let chat = chatAPI.getLocalChat(by: meta.id) {
                let scene = LarkSceneManager.Scene(
                    key: "Chat",
                    id: chat.chatterId,
                    title: searchResult.title.string,
                    userInfo: ["chatID": chat.id],
                    windowType: "single",
                    createWay: "drag")
                return scene
            } else {
                ChatterSearchViewModel.logger.error("[LarkSearch]local chat not found when druging shield group", additionalData: [
                    "chatId": meta.id
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

    func didSelectPersonCard(fromVC: UIViewController) {
        let sessionId = context.clickInfo?().sessionId
        let query = context.clickInfo?().query ?? ""
        let searchLocation = context.clickInfo?().searchLocation ?? "none"
        let scenceType = context.clickInfo?().sceneType ?? ""
        let imprId = context.clickInfo?().imprId ?? ""
        let currentFilters = context.clickInfo?().filters ?? []
        var isCache: Bool?
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        switch searchResult.meta {
        case .chatter(let chatterMeta):
            let resultType: String
            if chatterMeta.type == .ai {
                resultType = "myai"
                router.gotoMyAIProfile(fromVC: fromVC)
            } else {
                resultType = "contacts"
                router.gotoPersonCardWith(chatterID: chatterMeta.id, fromVC: fromVC)
            }
            self.clickPersonCardButton?(self.indexPath?.row, chatterMeta.id)
            self.saveClickPersonCardHistory?(self.indexPath, self)
            SearchTrackUtil.trackSearchProfileClick(userId: chatterMeta.id,
                                                    searchLocation: searchLocation,
                                                    query: query,
                                                    resultType: resultType,
                                                    sceneType: scenceType,
                                                    sessionId: sessionId,
                                                    imprId: imprId,
                                                    filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                                    bid: searchResult.bid,
                                                    entityType: searchResult.entityType,
                                                    isCache: isCache)
        case .cryptoP2PChat(let meta):
            chatAPI.fetchChats(by: [meta.id], forceRemote: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatMap) in
                    guard let self = self else { return }
                    if let chatterId = chatMap[meta.id]?.p2pOppositeId {
                        self.router.gotoPersonCardWith(chatterID: chatterId, fromVC: fromVC)
                        self.clickPersonCardButton?(self.indexPath?.row, chatterId)
                        self.saveClickPersonCardHistory?(self.indexPath, self)
                        SearchTrackUtil.trackSearchProfileClick(userId: chatterId,
                                                                searchLocation: searchLocation,
                                                                query: query,
                                                                resultType: "contacts",
                                                                sceneType: scenceType,
                                                                sessionId: sessionId,
                                                                imprId: imprId,
                                                                filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                                                bid: self.searchResult.bid,
                                                                entityType: self.searchResult.entityType,
                                                                isCache: isCache)
                    }
                })
                .disposed(by: disposeBag)
        case .shieldP2PChat(let meta):
            chatAPI.fetchChats(by: [meta.id], forceRemote: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatMap) in
                    guard let self = self else { return }
                    if let chatterId = chatMap[meta.id]?.p2pOppositeId {
                        self.router.gotoPersonCardWith(chatterID: chatterId, fromVC: fromVC)
                        self.clickPersonCardButton?(self.indexPath?.row, chatterId)
                        self.saveClickPersonCardHistory?(self.indexPath, self)
                        SearchTrackUtil.trackSearchProfileClick(userId: chatterId,
                                                                searchLocation: searchLocation,
                                                                query: query,
                                                                resultType: "contacts",
                                                                sceneType: scenceType,
                                                                sessionId: sessionId,
                                                                imprId: imprId,
                                                                filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                                                bid: self.searchResult.bid,
                                                                entityType: self.searchResult.entityType,
                                                                isCache: isCache)
                    }
                })
                .disposed(by: disposeBag)
        default:
            break
        }
    }

    private func _goToChatWith(chatterID: String, chatId: String, fromVC: UIViewController) {
        router.gotoChat(chatterID: chatterID, chatId: chatId, fromVC: fromVC, onError: { [weak self] err in
            if let routerError = err as? RouterError,
               let apiError = routerError.stack.first(where: { $0.underlyingError is APIError })?.underlyingError as? APIError,
               case .forbidPutP2PChat(let message) = apiError.type {
                let alertController = LarkAlertController()
                alertController.setContent(text: message)
                alertController.addPrimaryButton(text: BundleI18n.LarkSearch.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
                self?.userResolver.navigator.present(alertController, from: fromVC)
            }
        }, onCompleted: nil)
    }

    private func goToChatWith(chatterID: String, chatId: String, fromVC: UIViewController) {
        if !chatId.isEmpty {
            if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
                userResolver.navigator.switchTab(Tab.feed.url, from: fromVC, animated: true) { [weak self] _ in
                    guard let self = self else { return }
                    guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                    self._goToChatWith(chatterID: chatterID, chatId: chatId, fromVC: topVC)
                }
            } else {
                _goToChatWith(chatterID: chatterID, chatId: chatId, fromVC: fromVC)
            }
        } else {
            chatAPI.createP2pChats(uids: [chatterID])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak fromVC] (chats) in
                    guard let self = self, let chat = chats.first, let fromVC = fromVC else {
                        Self.logger.error("Fetch search chattter chat error")
                        return
                    }
                    self.router.gotoChat(withChat: chat, fromVC: fromVC)
                    self.peakFeedCard(self.feedAPI, feedCardId: chat.id, disposeBag: self.disposeBag)
                }, onError: { [weak self, weak fromVC] (error) in
                    guard self != nil, let fromVC = fromVC else { return }
                    Self.logger.error("Fetch search chattter chat error", error: error)
                    UDToast.removeToast(on: fromVC.view)
                    UDToast.showFailure(
                        with: BundleI18n.LarkSearch.Lark_Legacy_ProfileDetailCreateSingleChatFailed,
                        on: fromVC.view,
                        error: error
                    )
                })
                .disposed(by: disposeBag)
        }
    }

    private func goToBotChatWith(chatterMeta: ChatterMeta, fromVC: UIViewController) {
        guard chatterMeta.type == .bot else { return }
        UDToast.showLoading(with: "", on: fromVC.view)
        chatService.createP2PChat(userId: chatterMeta.id, isCrypto: false, chatSource: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC] (chatModel) in
                guard let `self` = self, let fromVC = fromVC else { return }
                self.router.gotoChat(withChat: chatModel, fromVC: fromVC)
                UDToast.removeToast(on: fromVC.view)
            }, onError: { [weak self, weak fromVC] (error) in
                guard self != nil, let fromVC = fromVC else { return }
                ChatterSearchViewModel.logger.error("点击机器人，创建会话失败", additionalData: ["Bot": chatterMeta.id], error: error)
                UDToast.removeToast(on: fromVC.view)
                UDToast.showFailure(
                    with: BundleI18n.LarkSearch.Lark_Legacy_ProfileDetailCreateSingleChatFailed,
                    on: fromVC.view,
                    error: error
                )
            }, onDisposed: {[weak self, weak fromVC] in
                guard self != nil, let fromVC = fromVC else { return }
                UDToast.removeToast(on: fromVC.view)
            })
            .disposed(by: disposeBag)
    }
}

typealias ChatterMeta = CommonChatterMetaType
