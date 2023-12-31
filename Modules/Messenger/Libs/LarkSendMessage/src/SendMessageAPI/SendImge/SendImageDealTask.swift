//
//  SendImageDealTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/6/6.
//

import Foundation
public final class SendImageDealTask<C: SendMessageDealTaskContext>: SendMessageDealTask<SendImageModel, C> {
    override public var identify: String { "SendImageDealTask" }

    public override func run(input: SendMessageProcessInput<SendImageModel>) {
        guard let message = input.message else {
            self.accept(.error(.dataError("message is nil", extraInfo: ["id": input.message?.id ?? ""])))
            RustSendMessageAPI.logger.error("can`t send message")
            return
        }
        // track send message
        LarkSendMessageTracker.trackStartSendMessage(token: message.cid)
        RustSendMessageAPI.logger.debug("start to send message：\(message.cid)")
        flowContext?.dealSendingMessage(message: message, replyInThread: input.replyInThread, parentMessage: input.parentMessage, chatFromWhere: input.context?.get(key: APIContext.chatFromWhere))
        self.accept(.success(input))
    }
}
