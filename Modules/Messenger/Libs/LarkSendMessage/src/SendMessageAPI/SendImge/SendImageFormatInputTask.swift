//
//  SendImageFormatInputTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/9.
//

import Foundation
import FlowChart // FlowChartContext

public protocol SendImageFormatInputTaskContext: FlowChartContext {
    func getImageMessageInfoCost(info: ImageMessageInfo) -> TimeInterval
}

// 发图片总流程预处理
public final class SendImageFormatInputTask<C: SendImageFormatInputTaskContext>: FlowChartTask<SendMessageProcessInput<SendImageModel>, SendMessageProcessInput<SendImageModel>, C> {
    override public var identify: String { "SendImageFormatInputTask" }

    public override func run(input: SendMessageProcessInput<SendImageModel>) {
        var output = input
        let processCost = self.flowContext?.getImageMessageInfoCost(info: input.model.imageMessageInfo) ?? 0
        input.sendMessageTracker?.beforeCreateQuasiMessage(context: input.context, processCost: processCost)
        let parentId = input.parentMessage?.id ?? ""
        let rootId = RustSendMessageModule.getRootId(parentMessage: input.parentMessage, replyInThread: input.replyInThread)

        output.rootId = rootId
        output.parentId = parentId
        self.accept(.success(output))
    }
}
