//
//  OncallSearchViewModel.swift
//  LarkSearch
//
//  Created by CharlieSu on 2018/11/29.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import RxSwift
import UniverseDesignToast
import LarkSDKInterface
import LKCommonsLogging
import LarkSceneManager
import EEAtomic
import LarkSearchCore
import LarkContainer
import LarkTab
import LarkMessengerInterface

final class OncallSearchViewModel: SearchCellViewModel {
    static let logger = Logger.log(OncallSearchViewModel.self, category: "Search")

    private let oncallAPI: OncallAPI
    private let currentChatterID: String
    private let chatAPI: ChatAPI
    let router: SearchRouter
    let searchResult: SearchResultType
    let userResolver: UserResolver
    let context: SearchViewModelContext

    var searchClickInfo: String {
        return "helpdesk"
    }

    var resultTypeInfo: String {
        return "helpdesk"
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

    let disposeBag = DisposeBag()
    @AtomicObject private var cacheOncallChatID: String?
    private var oncallChatID: String? {
        if case .oncall(let meta) = searchResult.meta, !meta.chatID.isEmpty {
            return meta.chatID
        }
        return cacheOncallChatID
    }

    init(userResolver: UserResolver,
         searchResult: SearchResultType,
         router: SearchRouter,
         currentChatterID: String,
         oncallAPI: OncallAPI,
         chatAPI: ChatAPI,
         context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
        self.oncallAPI = oncallAPI
        self.currentChatterID = currentChatterID
        self.chatAPI = chatAPI
        self.context = context
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        guard case let .oncall(meta) = searchResult.meta else {
            OncallSearchViewModel.logger.error("[LarkSearch] oncall search result can not jump with empty oncallMeta")
            return nil }

        let hud = UDToast.showLoading(with: "", on: vc.view, disableUserInteraction: true)

        let oncallChatID: Observable<String>
        if let chatID = self.oncallChatID { // 已有相应会话
            oncallChatID = Observable.just(chatID)
        } else {
            oncallChatID = self.oncallAPI.putOncallChat(userId: currentChatterID, oncallId: meta.id, additionalData: nil)
            .do(onNext: { [weak self](id) in
                if !id.isEmpty { self?.cacheOncallChatID = id }
            })
        }

        let chatAPI = self.chatAPI
        let router = self.router
        oncallChatID
            .flatMap { (chatID: String) -> Observable<Chat?> in
                if chatID.isEmpty {
                    OncallSearchViewModel.logger.error("[LarkSearch] chat id is empty, can not push to chat!")
                }
                return chatAPI
                    .fetchChats(by: [chatID], forceRemote: false)
                    .map { (chatMap: [String: Chat]) -> Chat? in
                        let chat = chatMap[chatID]
                        if chat == nil {
                            OncallSearchViewModel.logger.error("[LarkSearch] Get on call chat failed", additionalData: ["chatID": chatID])
                        }
                        return chat
                    }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                hud.remove()
                chat.flatMap { [weak self] (chat) in
                    var searchOuterService: SearchOuterService? { try? self?.userResolver.resolve(assert: SearchOuterService.self) }
                    if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
                        self?.userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: false) { _ in
                            guard let self = self else { return }
                            guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                            router.gotoChat(withChat: chat, fromVC: topVC)
                        }
                    } else {
                        router.gotoChat(withChat: chat, fromVC: vc)
                    }
                }
            }, onError: { error in
                hud.showFailure(with: BundleI18n.LarkSearch.Lark_Legacy_NetworkOrServiceError, on: vc.view, error: error)
            }, onCompleted: {
                hud.remove()
            }, onDisposed: {
                hud.remove()
            })
            .disposed(by: disposeBag)
        return nil
    }

    func supportDragScene() -> Scene? {
        guard case let .oncall(meta) = searchResult.meta else {
            OncallSearchViewModel.logger.error("[LarkSearch] oncall search result can not jump with empty oncallMeta")
            return nil }

        if let chatID = self.oncallChatID {
            return LarkSceneManager.Scene(
                key: "Chat",
                id: chatID,
                title: searchResult.title.string,
                windowType: "help_desk",
                createWay: "drag"
            )
        }

        // NOTE: 因为异步，首次可能无响应。兜底措施
        self.oncallAPI.putOncallChat(userId: currentChatterID, oncallId: meta.id, additionalData: nil)
        .subscribe(onNext: { [weak self](id) in
            if !id.isEmpty { self?.cacheOncallChatID = id }
        }).disposed(by: disposeBag)
        return nil
    }
}
