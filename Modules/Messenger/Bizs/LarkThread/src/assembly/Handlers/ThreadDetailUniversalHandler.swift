//
//  ThreadDetailUniversalHandler.swift
//  LarkThread
//
//  Created by ByteDance on 2022/7/1.
//

import Foundation
import RxSwift
import Swinject
import LarkCore
import LarkModel
import EENavigator
import LKCommonsLogging
import LarkMessageBase
import LarkMessageCore
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import RustPB
import LarkContainer
import UIKit
import LarkNavigator

final class ThreadDetailUniversalHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private let disposeBag: DisposeBag = DisposeBag()
    private static let logger = Logger.log(ThreadDetailUniversalHandler.self, category: "ThreadDetailUniversalIDBody")

    func handle(_ body: ThreadDetailUniversalIDBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        chatAPI.fetchChat(by: body.chatID, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { chat in
                Self.logger.info("jump info chatID\(body.chatID) --threadId: \(body.threadId) --position: \(body.position)")
                guard let chat = chat else {
                    res.end(error: nil)
                    Self.logger.info("get current chat nil info")
                    return
                }
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: body.threadId,
                                                    loadType: body.loadType,
                                                    position: body.position,
                                                    keyboardStartupState: body.keyboardStartupState,
                                                    sourceType: body.sourceType)
                    res.redirect(body: body)
                } else {
                    let body = ReplyInThreadByIDBody(threadId: body.threadId,
                                                     loadType: body.loadType,
                                                     position: body.position,
                                                     keyboardStartupState: body.keyboardStartupState)
                    res.redirect(body: body)
                }
            }, onError: { error in
                Self.logger.error("try local chat fail", error: error)
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }
}
