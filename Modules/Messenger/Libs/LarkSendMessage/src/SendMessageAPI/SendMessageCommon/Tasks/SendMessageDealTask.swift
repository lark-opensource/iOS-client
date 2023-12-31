//
//  SendMessageDealTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/9.
//

import Foundation
import FlowChart // FlowChartContext
import LarkModel // Message

public protocol SendMessageDealTaskContext: FlowChartContext {
    func dealSendingMessage(message: LarkModel.Message,
                            replyInThread: Bool,
                            parentMessage: LarkModel.Message?,
                            chatFromWhere: String?)
}

extension RustSendMessageAPI: SendMessageDealTaskContext {}

public class SendMessageDealTask<M: SendMessageModelProtocol, C: SendMessageDealTaskContext>: FlowChartTask<SendMessageProcessInput<M>, SendMessageProcessInput<M>, C> {
    override public var identify: String { "SendMessageDealTask" }

    public override func run(input: SendMessageProcessInput<M>) {
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
