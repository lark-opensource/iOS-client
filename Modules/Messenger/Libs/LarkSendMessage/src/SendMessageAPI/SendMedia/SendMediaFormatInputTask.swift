//
//  SendMediaFormatInputTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/16.
//

import UIKit
import Foundation
import FlowChart // FlowChartContext

public protocol SendMediaFormatInputTaskContext: FlowChartContext {
}

public final class SendMediaFormatInputTask<C: SendMediaFormatInputTaskContext>: FlowChartTask<SendMessageProcessInput<SendMediaModel>, SendMessageProcessInput<SendMediaModel>, C> {
    override public var identify: String { "SendMediaFormatInputTask" }

    public override func run(input: SendMessageProcessInput<SendMediaModel>) {
        var ouput = input
        let params = input.model.params
        let parentId = input.parentMessage?.id ?? ""
        let rootId = RustSendMessageModule.getRootId(parentMessage: input.parentMessage, replyInThread: input.replyInThread)

        let start = CACurrentMediaTime()
        input.sendMessageTracker?.beforeCreateQuasiMessage(context: input.context,
                                                           processCost: CACurrentMediaTime() - start)
        var content = QuasiContent()
        content.path = params.exportPath
        content.name = params.name
        if let data = params.imageData {
            content.image = data
        } else {
            let data = params.image.jpegData(compressionQuality: 0.75)
            if let data = data {
                content.image = data
            }
        }
        content.width = Int32(params.mediaSize.width)
        content.height = Int32(params.mediaSize.height)
        content.duration = params.duration
        content.mediaSource = .lark
        content.compressPath = params.compressPath

        ouput.rootId = rootId
        ouput.parentId = parentId
        ouput.model.content = content
        self.accept(.success(ouput))
    }
}
