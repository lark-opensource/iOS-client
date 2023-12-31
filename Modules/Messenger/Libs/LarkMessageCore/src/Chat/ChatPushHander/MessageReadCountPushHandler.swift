//
//  MessageReadCountPushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class MessageReadCountPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return MessageReadCountPushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

//此处监听的是进入已读/未读详情页后，端上(非sdk)产生的push
final class MessageReadCountPushHandler: PushHandler {
    var channelId: String

    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushMessageReadstatus.self)
            .filter { [weak self] (push) -> Bool in
                return push.channelId == self?.channelId ?? ""
            }
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                self.dataSourceAPI?.update(messageIds: [push.messageId], doUpdate: { (data) -> PushData in
                    data.message.unreadCount = push.unreadCount
                    data.message.readCount = push.readCount
                    return data
                })
            }).disposed(by: disposeBag)
    }
}
