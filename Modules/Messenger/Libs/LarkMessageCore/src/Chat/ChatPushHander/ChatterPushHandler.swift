//
//  ChatterPushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class ChatterPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return ChatterPushHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class ChatterPushHandler: PushHandler {
    let disposeBag: DisposeBag = DisposeBag()

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushChatters.self)
            .map { (push) -> [Chatter] in
                return push.chatters
            }
            .subscribe(onNext: { [weak self] (pushChatters) in
                guard let `self` = self else { return }
                self.dataSourceAPI?.update(original: { [weak self] (data) -> PushData? in
                    var needUpdate = false
                    for pushChatter in pushChatters {
                        self?.updateMessageChatters(message: data.message, chatterId: pushChatter.id, update: { (chatter) in
                            needUpdate = true
                            pushChatter.chatExtra = chatter.chatExtra
                            return pushChatter
                        })
                    }
                    if needUpdate {
                        return data
                    }
                    return nil
                })
            }).disposed(by: disposeBag)
    }

    func updateMessageChatters(message: Message, chatterId: String, update: (Chatter) -> Chatter) {
        if let fromChatter = message.fromChatter, fromChatter.id == chatterId {
            message.fromChatter = update(fromChatter)
        }
        if let pinChatter = message.pinChatter, pinChatter.id == chatterId {
            message.pinChatter = update(pinChatter)
        }
        if let recaller = message.recaller, recaller.id == chatterId {
            message.recaller = update(recaller)
        }
        for reaction in message.reactions {
            for (index, reactionChatter) in (reaction.chatters ?? []).enumerated() where reactionChatter.id == chatterId {
                reaction.chatters?[index] = update(reactionChatter)
            }
        }
        if message.threadMessageType == .threadRootMessage {
            for reply in message.replyInThreadLastReplies {
                if let fromChatter = reply.fromChatter, fromChatter.id == chatterId {
                    reply.fromChatter = update(fromChatter)
                }
            }
        }
    }
}
