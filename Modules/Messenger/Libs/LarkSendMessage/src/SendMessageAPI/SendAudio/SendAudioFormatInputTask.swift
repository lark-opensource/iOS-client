////
////  SendAudioFormatInputTask.swift
////  LarkSDK
////
////  Created by JackZhao on 2022/1/16.
////
//

import Foundation
import FlowChart // FlowChartTask
import LarkAudioKit // OpusUtil

public protocol SendAudioFormatInputTaskContext: FlowChartContext {
}

public final class SendAudioFormatInputTask<C: SendAudioFormatInputTaskContext>: FlowChartTask<SendMessageProcessInput<SendAudioModel>,
    SendMessageProcessInput<SendAudioModel>, C> {
    override public var identify: String { "SendAudioFormatInputTask" }

    public override func run(input: SendMessageProcessInput<SendAudioModel>) {
        var output = input
        let model = input.model
        let parentId = input.parentMessage?.id ?? ""
        let rootId = RustSendMessageModule.getRootId(parentMessage: input.parentMessage, replyInThread: input.replyInThread)

        input.sendMessageTracker?.beforeCreateQuasiMessage(context: input.context, processCost: nil)

        var content = QuasiContent()
        if case .data(let data, _) = model.info.dateType {
            let audio = data
            if OpusUtil.isWavFormat(data) {
                content.audio = OpusUtil.encode_wav_data(data) ?? data
            } else {
                content.audio = data
            }
        }
        content.duration = Int32(model.info.length * 1000)
        if let text = model.info.text {
            content.text = text
        }

        output.rootId = rootId
        output.parentId = parentId
        output.model.content = content
        self.accept(.success(output))
    }
}
