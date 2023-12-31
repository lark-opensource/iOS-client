//
//  UrgentPushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class UrgentPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return UrgentPushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class UrgentPushHandler: PushHandler {
    var channelId: String
    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushUrgent.self)
            .map { (push) -> Message in
                return push.urgentInfo.message
            }
            .filter { [weak self] (message) -> Bool in
                return message.channel.id == self?.channelId ?? ""
            }
            .subscribe(onNext: { [weak self] (urgentMessage) in
                guard let `self` = self else { return }
                self.perform {
                    //虽然信号发射的是message,但信息并不完整，不可做全部替换，此处仅更新isUrgent字段
                    self.dataSourceAPI?.update(messageIds: [urgentMessage.id], doUpdate: { (data) -> PushData? in
                        if data.message.isUrgent {
                            return nil
                        }
                        data.message.isUrgent = true
                        return data
                    })
                }
            }).disposed(by: disposeBag)
    }
}
