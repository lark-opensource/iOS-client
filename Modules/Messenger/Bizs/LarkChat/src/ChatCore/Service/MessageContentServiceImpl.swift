//
//  MessageContentServiceImpl.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/9/27.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer

final class MessageContentServiceImpl: MessageContentService {
    private let messageAPI: MessageAPI

    public init(userResolver: UserResolver) throws {
        messageAPI = try userResolver.resolve(assert: MessageAPI.self)
    }

    func getMessageContent(messageIds: [String]) -> Observable<[String: Message]>? {
        return self.messageAPI.fetchMessagesMap(ids: messageIds, needTryLocal: true)
    }
}
