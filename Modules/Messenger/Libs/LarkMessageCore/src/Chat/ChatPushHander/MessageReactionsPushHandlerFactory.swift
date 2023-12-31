//
//  MessageReactionsPushHandlerFactory.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/7/20.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import RxSwift

final class MessageReactionsPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return MessageReactionsPushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class MessageReactionsPushHandler: PushHandler {
    var channelId: String

    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushMessageReactions.self)
            .filter { [weak self] (push) -> Bool in
                return push.chatId == self?.channelId ?? ""
            }
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                self.perform {
                    let messageIds = Array(push.messageReactions.keys)
                    self.dataSourceAPI?.update(messageIds: messageIds, doUpdate: { (data) -> PushData? in
                        guard let reactions = push.messageReactions[data.message.id] else { return nil }
                        data.message.reactions = reactions
                        return data
                    })
                }
            }).disposed(by: disposeBag)
    }
}
