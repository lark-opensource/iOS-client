//
//  SendMessageFormatInputTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import FlowChart // FlowChartContext

public protocol SendMessageFormatInputTaskContext: FlowChartContext {}

extension RustSendMessageAPI: SendMessageFormatInputTaskContext {}

public final class SendMessageFormatInputTask<M: SendMessageModelProtocol, C: SendMessageDealTaskContext>: FlowChartTask<SendMessageProcessInput<M>, SendMessageProcessInput<M>, C> {
    override public var identify: String { "SendMessageFormatInputTask" }

    public override func run(input: SendMessageProcessInput<M>) {
        var output = input
        let parentId = input.parentMessage?.id ?? (input.parentId ?? "")
        let rootId = RustSendMessageModule.getRootId(parentMessage: input.parentMessage, replyInThread: input.replyInThread)
        input.sendMessageTracker?.beforeCreateQuasiMessage(context: input.context, processCost: nil)
        output.rootId = rootId
        output.parentId = parentId
        self.accept(.success(output))
    }
}
