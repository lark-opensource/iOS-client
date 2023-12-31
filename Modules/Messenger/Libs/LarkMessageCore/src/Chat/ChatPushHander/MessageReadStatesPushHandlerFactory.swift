//
//  MessageReadStatesPushHandlerFactory.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/7/20.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import LarkExtensions
import RxSwift
import LKCommonsLogging
import LarkSetting

final class MessageReadStatesPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return MessageReadStatesPushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class MessageReadStatesPushHandler: PushHandler {
    private static let logger = Logger.log(MessageReadStatesPushHandler.self, category: "PushHandler.MessageReadStatesPushHandler")
    var channelId: String
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    private lazy var readStatesProtectEnable: Bool = fgService?.staticFeatureGatingValue(with: "chat.message.readstate_protect") ?? false

    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushMessageReadStates.self)
            .filter { [weak self] (push) -> Bool in
                return push.messageReadStates.chatID == self?.channelId ?? ""
            }
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                self.perform {
                    let messageIds = Set(push.messageReadStates.readStates.keys).union(Set(push.messageReadStates.readStatesExtra.keys))
                    self.dataSourceAPI?.update(messageIds: Array(messageIds), doUpdate: { (data) -> PushData? in
                        var needUpdate: Bool = false
                        if let readState = push.messageReadStates.readStates[data.message.id] {
                            //如果最新的数据已读数小于之前，不做更新
                            if self.readStatesProtectEnable,
                               readState.unreadCount + readState.readCount == data.message.unreadCount + data.message.readCount,
                               data.message.readCount > readState.readCount {
                                needUpdate = false
                                Self.logger.error("""
                                    chatTrace push messageReadStates exception \(push.messageReadStates.chatID)
                                    \(readState.unreadCount) \(readState.readCount)
                                    \(data.message.unreadCount) \(data.message.readCount)
                                    """)
                            } else {
                                data.message.unreadCount = readState.unreadCount
                                data.message.readCount = readState.readCount
                                data.message.readAtChatterIds = readState.readAtChatterIds
                                needUpdate = true
                            }
                        }
                        if let readStateExtra = push.messageReadStates.readStatesExtra[data.message.id],
                           readStateExtra.meRead, !data.message.meRead {
                            needUpdate = true
                            data.message.meRead = readStateExtra.meRead
                        }
                        return needUpdate ? data : nil
                    })
                }
            }).disposed(by: disposeBag)
    }
}
