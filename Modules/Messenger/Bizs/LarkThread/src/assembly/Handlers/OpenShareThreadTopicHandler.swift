//
//  OpenShareThreadTopicHandler.swift
//  LarkThread
//
//  Created by zc09v on 2019/6/17.
//

import Foundation
import UIKit
import EENavigator
import RxSwift
import LarkModel
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkNavigator
import LarkContainer

final class OpenShareThreadTopicHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    static let logger = Logger.log(OpenShareThreadTopicHandler.self, category: "LarkThread.OpenShareThreadTopicHandler")
    private let chatAPI: ChatAPI
    private let threadAPI: ThreadAPI
    private var currentChatterId: String { userResolver.userID }
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver) throws {
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.threadAPI = try userResolver.resolve(assert: ThreadAPI.self)
        super.init(resolver: userResolver)
    }

    func handle(_ body: OpenShareThreadTopicBody, req: EENavigator.Request, res: Response) throws {
        let threadId = body.threadid
        let chatId = body.chatid
        func toThreadDetail() {
            var naviParams = NaviParams()
            naviParams.openType = .push
            res.redirect(body: ThreadDetailByIDBody(threadId: threadId, loadType: .root), naviParams: naviParams)
        }

        func showJoinGroupApply() {
            let joinBody = JoinGroupApplyBody(
                chatId: chatId,
                way: .viaShareTopic,
                callback: { (status) in
                    switch status {
                    case .hadJoined:
                        toThreadDetail()
                    case .waitAccept, .expired, .fail, .unTap, .sharerQuit,
                         .cancel, .ban, .groupDisband, .noPermission, .numberLimit, .contactAdmin, .nonCertifiedTenantRefuse:
                        break
                    }
                })
            res.redirect(body: joinBody)
        }

        self.chatAPI
            .fetchChats(by: [chatId], forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chats) in
                guard let chat = chats[chatId] else {
                    OpenShareThreadTopicHandler.logger.error("话题分享跳转失败 UserTypedRouterHandler fetch chat fail \(chatId) \(threadId)")
                    res.end(error: nil)
                    return
                }
                let needJoinChatApply = (chat.role != .member)
                if needJoinChatApply {
                    showJoinGroupApply()
                } else {
                    toThreadDetail()
                }
            }, onError: { (error) in
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }
}
