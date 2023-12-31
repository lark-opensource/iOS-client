//
//  SendFileFormatInputTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/19.
//

import Foundation
import FlowChart // FlowChartTask

public protocol SendFileFormatInputTaskContext: FlowChartContext {
}

public final class SendFileFormatInputTask<C: SendFileFormatInputTaskContext>: FlowChartTask<SendMessageProcessInput<SendFileModel>, SendMessageProcessInput<SendFileModel>, C> {
    override public var identify: String { "SendFileFormatInputTask" }

    public override func run(input: SendMessageProcessInput<SendFileModel>) {
        var output = input
        if output.model.executeBeforeCreateQuasiCallback {
            input.sendMessageTracker?.beforeCreateQuasiMessage(context: input.context,
                                                               processCost: nil)
        }
        let parentId = input.parentMessage?.id ?? ""
        let rootId = RustSendMessageModule.getRootId(parentMessage: input.parentMessage, replyInThread: input.replyInThread)

        var content = QuasiContent()
        content.path = input.model.path
        content.fileSource = .larkServer
        content.name = input.model.name

        output.rootId = rootId
        output.parentId = parentId
        output.model.content = content
        self.accept(.success(output))
    }
}
