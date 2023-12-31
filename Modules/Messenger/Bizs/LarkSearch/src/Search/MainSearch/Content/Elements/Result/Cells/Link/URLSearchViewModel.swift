//
//  URLSearchViewModel.swift
//  LarkSearch
//
//  Created by SuPeng on 5/24/19.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import LarkSDKInterface
import LarkSearchCore
import LarkContainer
import LarkTab
import LarkMessengerInterface

final class URLSearchViewModel: SearchCellViewModel, UserResolverWrapper {

    let searchResult: SearchResultType
    private let chatAPI: ChatAPI
    let router: SearchRouter
    let userResolver: UserResolver
    private let context: SearchViewModelContext
    init(userResolver: UserResolver, searchResult: SearchResultType, chatAPI: ChatAPI, router: SearchRouter, context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.chatAPI = chatAPI
        self.router = router
        self.context = context
    }

    /// 埋点信息
    var searchClickInfo: String {
        return "link"
    }

    var resultTypeInfo: String {
        return "link"
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

    func gotoChat(from vc: UIViewController) {
        if case let .link(meta) = searchResult.meta {
            if let chat = chatAPI.getLocalChat(by: meta.chatID) {
                let enableSearchiPadSpliteMode = SearchFeatureGatingKey.enableSearchiPadSpliteMode.isUserEnabled(userResolver: self.userResolver)
                if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad(), !enableSearchiPadSpliteMode {
                    userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: false) { [weak self] _ in
                        guard let self = self else { return }
                        guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        self.jumpToMessage(meta: meta, chat: chat, fromVC: topVC)
                    }
                } else {
                    jumpToMessage(meta: meta, chat: chat, fromVC: vc)
                }
            } else {
                MessageSearchViewModel.logger.error("[LarkSearch] 点击消息，未找到本地chat", additionalData: [
                    "chatId": meta.chatID,
                    "messageId": meta.id
                    ])
            }
        }
    }

    private func jumpToMessage(meta: SearchMetaLinkType, chat: LarkModel.Chat, fromVC: UIViewController) {
        if chat.chatMode == .threadV2 {
            router.gotoThreadDetail(withThreadId: meta.threadID, position: meta.threadPosition, fromVC: fromVC)
        } else {
            router.gotoChat(withChat: chat, position: meta.position, fromVC: fromVC)
        }
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        if case let .link(meta) = searchResult.meta {
            URL(string: meta.originalURL)?.lf.toHttpUrl().flatMap {
                navigator.pushOrShowDetail($0, from: vc)
            }
        }
        return nil
    }
}
