//
//  MessageFeedbackStatusPushHandlerFactory.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/6/21.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import RxSwift
import LKCommonsLogging

final class MessageFeedbackStatusPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: LarkContainer.UserResolver) -> PushHandler {
        return MessageFeedbackStatusPushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class MessageFeedbackStatusPushHandler: PushHandler {
    private let logger = Logger.log(MessageFeedbackStatusPushHandler.self, category: "LarkMessageCore.MessageFeedbackStatusPushHandler")
    var channelId: String

    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        try self.userResolver.userPushCenter.observable(for: PushMessageFeedbackStatus.self)
            .filter { [weak self] (push) -> Bool in
                return push.chatId == self?.channelId ?? ""
            }
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                self.perform {
                    let messageIds = Array(push.messageFeedbackStatus.keys)
                    self.dataSourceAPI?.update(messageIds: messageIds, doUpdate: { [weak self] (data) -> PushData? in
                        guard let feedbackStatus = push.messageFeedbackStatus[data.message.id] else { return nil }
                        // 排查点击赞踩icon没有变化的日志：看日志请求、赞踩Push、界面刷新信号一切正常，https://logifier-va.byteintl.net/lg/batch/6429/
                        // 怀疑是消息赞踩状态被提前刷到终态了，导致此处无法刷新，这里去掉判断，强制界面刷新一次
                        self?.logger.info("my ai handle message feedback push: \(push.chatId) \(data.message.id) \(data.message.feedbackStatus) \(feedbackStatus)")
                        data.message.feedbackStatus = feedbackStatus
                        return data
                    })
                }
            }).disposed(by: disposeBag)
    }
}
