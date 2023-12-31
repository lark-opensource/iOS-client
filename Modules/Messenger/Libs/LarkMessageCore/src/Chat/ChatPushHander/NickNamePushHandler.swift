//
//  NickNamePushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class NickNamePushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return NickNamePushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class NickNamePushHandler: PushHandler {
    var channelId: String
    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushChannelNickname.self).filter({ [weak self] (nickNameInfo) -> Bool in
                return nickNameInfo.channelId == self?.channelId ?? ""
            })
            .subscribe(onNext: { [weak self] (nickNameInfo) in
                guard let `self` = self else { return }
                self.dataSourceAPI?.update(original: { [weak self] (data) -> PushData? in
                    var needUpdate = false
                    self?.updateMessageChatters(message: data.message, chatterId: nickNameInfo.chatterId, update: { (chatter) in
                        needUpdate = true
                        chatter.chatExtra?.nickName = nickNameInfo.newNickname
                        return chatter
                    })
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
    }
}
