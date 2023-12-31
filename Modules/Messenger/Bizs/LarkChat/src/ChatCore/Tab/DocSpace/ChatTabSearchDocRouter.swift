//
//  ChatTabSearchDocRouter.swift
//  LarkChat
//
//  Created by Zigeng on 2022/5/6.
//

import UIKit
import RxSwift
import LarkModel
import LarkCore
import Swinject
import EENavigator
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer
import LarkFeatureGating
import LarkMessengerInterface
import UniverseDesignToast
import LarkKASDKAssemble
import Foundation
import RxCocoa
import Homeric
import LKCommonsTracker
import LarkOpenChat
import LarkSetting

protocol ChatTabSearchDocRouter: AnyObject {
    func pushDocViewController(chatId: String, docUrl: String, fromVC: UIViewController)
    func pushChatViewController(chatId: String, toMessagePosition: Int32, fromVC: UIViewController, extraInfo: [String: Any])
    func jumpToTab(_ tab: ChatTabContent, targetVC: UIViewController)
    func preloadDocs(_ url: String)
}

final class DefaultChatTabSearchDocRouter: ChatTabSearchDocRouter, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(DefaultChatTabSearchDocRouter.self, category: "Search.router")
    private let chatDependency: ChatDocDependency
    static let preLoadDocsTypeValue: Int = 9999
    private lazy var loadConfig: [Int] = {
        if let settings = try? userResolver.settings.setting(with: .make(userKeyLiteral: "preload_doc_chat_types")) {
            return settings["supportTypes"] as? [Int] ?? []
        }
        return []
    }()

    private let jumpToTab: (ChatTabContent, UIViewController) -> Void
    init(userResolver: UserResolver, jumpToTab: @escaping (ChatTabContent, UIViewController) -> Void) throws {
        self.userResolver = userResolver
        self.chatDependency = try userResolver.resolve(assert: ChatDocDependency.self)
        self.jumpToTab = jumpToTab
    }

    func pushDocViewController(chatId: String, docUrl: String, fromVC: UIViewController) {
        guard let url = URL(string: docUrl) else {
            Self.logger.error("wrong docUrl")
            return
        }
        navigator.push(url.append(name: "from", value: "space_list_tab"), from: fromVC)
        let token = chatDependency.isSupportURLType(url: url).2
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_LIST_CLICK,
                             params: ["click": "doc",
                                      "target": "ccm_docs_page_view",
                                      "file_id": token],
                             md5AllowList: ["file_id"]))
    }

    func pushChatViewController(chatId: String, toMessagePosition: Int32, fromVC: UIViewController, extraInfo: [String: Any]) {
        let body = ChatControllerByIdBody(
            chatId: chatId,
            position: toMessagePosition
        )
        navigator.push(body: body, from: fromVC)
        // 埋点数据
        if let docUrl = extraInfo["docUrl"] as? String,
           let url = URL(string: docUrl) {
           let token = chatDependency.isSupportURLType(url: url).2
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_LIST_CLICK,
                                  params: ["click": "jump_to_chat",
                                           "target": "im_chat_main_view",
                                           "file_id": token],
                                  md5AllowList: ["file_id"]))

        }
    }

    func jumpToTab(_ tab: ChatTabContent, targetVC: UIViewController) {
        self.jumpToTab(tab, targetVC)
    }

    func preloadDocs(_ url: String) {
        if self.loadConfig.contains(DefaultChatTabSearchDocRouter.preLoadDocsTypeValue) {
            guard let docUrl = URL(string: url) else {
                return
            }
            chatDependency.preloadDocFeed(docUrl.absoluteString, from: "space_list_tab")
        }
    }
}
