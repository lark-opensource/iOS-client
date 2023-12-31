//
//  MessageSearchViewModel.swift
//  Lark
//
//  Created by ChalrieSu on 02/04/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging
import LarkModel
import LarkUIKit
import LarkSDKInterface
import LarkSceneManager
import LarkSearchCore
import EENavigator
import LarkAppLinkSDK
import LarkContainer
import LarkTab
import LarkMessengerInterface

final class MessageSearchViewModel: SearchCellViewModel {
    static let logger = Logger.log(MessageSearchViewModel.self, category: "Module.IM.Search")

    private let chatAPI: ChatAPI
    let router: SearchRouter
    let searchResult: SearchResultType
    private let context: SearchViewModelContext

    var searchClickInfo: String { return "msg" }

    var resultTypeInfo: String { return "messages" }

    let userResolver: UserResolver
    init(userResolver: UserResolver, searchResult: SearchResultType, chatAPI: ChatAPI, router: SearchRouter, context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.chatAPI = chatAPI
        self.router = router
        self.context = context
    }

    private func jumpToMessage(messageMeta: SearchMetaMessageType, chat: LarkModel.Chat, fromVC: UIViewController) {
        if chat.chatMode == .threadV2 {
            router.gotoThreadDetail(withThreadId: messageMeta.threadID, position: messageMeta.threadPosition, fromVC: fromVC)
        } else {
            if messageMeta.position == replyInThreadMessagePosition {
                router.gotoReplyInThreadDetail(threadId: messageMeta.threadID,
                                               threadPosition: messageMeta.threadPosition,
                                               fromVC: fromVC)
            } else {
                router.gotoChat(withChat: chat, position: messageMeta.position, fromVC: fromVC)
            }
        }
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        switch searchResult.meta {
        case .message(let messageMeta):
            if let chat = chatAPI.getLocalChat(by: messageMeta.chatID) {
                let enableSearchiPadSpliteMode = SearchFeatureGatingKey.enableSearchiPadSpliteMode.isUserEnabled(userResolver: self.userResolver)
                if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad(), !enableSearchiPadSpliteMode {
                    userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: false) { [weak self] _ in
                        guard let self = self else { return }
                        guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        self.jumpToMessage(messageMeta: messageMeta, chat: chat, fromVC: topVC)
                    }
                } else {
                    jumpToMessage(messageMeta: messageMeta, chat: chat, fromVC: vc)
                }
            } else {
                MessageSearchViewModel.logger.error("[LarkSearch] 点击消息，未找到本地chat", additionalData: [
                    "chatId": messageMeta.chatID,
                    "messageId": messageMeta.id
                ])
            }
        default:
            break
        }
        return nil
    }

    func supportDragScene() -> Scene? {
        switch searchResult.meta {
        case .message(let messageMeta):
            if let chat = chatAPI.getLocalChat(by: messageMeta.chatID) {
                if chat.chatMode == .threadV2 {
                    var userInfo: [String: String] = [:]
                    userInfo["position"] = "\(messageMeta.threadPosition)"
                    let scene = LarkSceneManager.Scene(
                        key: "Thread",
                        id: messageMeta.threadID,
                        title: chat.displayName,
                        userInfo: userInfo,
                        windowType: "channel",
                        createWay: "drag")
                    return scene
                } else {
                    var windowType: String = "group"
                    if chat.isMeeting {
                        windowType = "event_group"
                    } else if !chat.oncallId.isEmpty {
                        windowType = "help_desk"
                    }

                    var userInfo: [String: String] = [:]
                    userInfo["position"] = "\(messageMeta.position)"
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
                MessageSearchViewModel.logger.error("[LarkSearch] 拖拽消息，未找到本地chat", additionalData: [
                    "chatId": messageMeta.chatID,
                    "messageId": messageMeta.id
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

    func didSelectURLAttachmentCard(withURL url: String, fromVC vc: UIViewController) {
        if let url = URL(string: url)?.lf.toHttpUrl() {
            userResolver.navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: vc)
        } else {
            Self.logger.error("[LarkSearch] useless url \(url)")
        }
        let sessionId = context.clickInfo?().sessionId
        let query = context.clickInfo?().query ?? ""
        let searchLocation = context.clickInfo?().searchLocation ?? "none"
        let scenceType = context.clickInfo?().sceneType ?? ""
        let imprId = context.clickInfo?().imprId ?? ""
        let currentFilters = context.clickInfo?().filters ?? []
        var isCache: Bool?
        if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackSearchMessageURLAttachmentClick(searchLocation: searchLocation,
                                                             query: query,
                                                             sceneType: scenceType,
                                                             sessionId: sessionId,
                                                             imprId: imprId,
                                                             filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                                             bid: searchResult.bid,
                                                             entityType: searchResult.entityType,
                                                             clickType: "result_click", resultType: "messages",
                                                             subResultType: "link",
                                                             attachmentType: "multimedia_card",
                                                             isCache: isCache)
    }
}
