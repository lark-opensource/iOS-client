//
//  ReadStatusHandler.swift
//  LarkChat
//
//  Created by liuwanlin on 2018/8/24.
//

import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import LarkModel
import LarkNavigator

final class ReadStatusHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    func handle(_ body: ReadStatusBody, req: EENavigator.Request, res: Response) throws {
        let messageId = body.messageID
        let messagesOb = try resolver.resolve(assert: MessageAPI.self).fetchLocalMessage(id: messageId)
        let chatOb = try resolver.resolve(assert: ChatAPI.self).fetchChats(by: [body.chatID], forceRemote: false)
        let resolver = self.userResolver

        let onError = { (error) in
            res.end(error: error)
        }
        Observable.zip(messagesOb, chatOb)
            .flatMap { (message, chatMap) -> Observable<(Message, Chat)> in
                if let chat = chatMap[body.chatID] {
                    return .just((message, chat))
                }
                return .error(RouterError.invalidParameters("chat miss \(body.chatID)"))
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (result) in
              do {
                let viewModel = ReadStatusViewModel(
                    userResolver: resolver,
                    readStatusType: body.type,
                    message: result.0,
                    currentChatterId: resolver.userID,
                    chat: result.1,
                    pushCenter: try resolver.userPushCenter,
                    messageAPI: try resolver.resolve(assert: MessageAPI.self),
                    chatterAPI: try resolver.resolve(assert: ChatterAPI.self),
                    urgentAPI: try resolver.resolve(assert: UrgentAPI.self)
                )
                let controller = ReadStatusContainerViewController(viewModel: viewModel)
                res.end(resource: controller)
              } catch { onError(error) }
            }, onError: onError)
            .disposed(by: self.disposeBag)
        res.wait()
    }
}
