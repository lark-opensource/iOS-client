////
////  SendAudioCreateQuasiMsgTask.swift
////  LarkSDK
////
////  Created by JackZhao on 2022/1/16.
////
//

import UIKit
import Foundation
import FlowChart // FlowChartTask
import LarkSetting // FeatureGatingManager
import LarkContainer

public final class SendAudioCreateQuasiMsgTask<C: SendAudioMsgOnScreenTaskContext>: FlowChartTask<SendMessageProcessInput<SendAudioModel>, SendMessageProcessInput<SendAudioModel>, C> {
    override public var identify: String { "SendAudioCreateQuasiMsgTask" }

    public override func run(input: SendMessageProcessInput<SendAudioModel>) {
        guard let content = input.model.content, let context = flowContext,
            let userResolver = try? Container.shared.getUserResolver(userID: context.currentChatter.id)
        else {
            self.accept(.error(.dataError("content or client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let client = context.client
        var uploadID: String?
        // 录音场景时会边录边传，SEND_MESSAGE时只需要把uploadID传入即可，不需要再传语音数据Data
        if case .uploadID(let id) = input.model.info.dateType {
            uploadID = id
        }
        // 语音+文字场景：之前语音数据Data是在SEND_MESSAGE时传给Rust进行上传；现在做了一个优化：识别文字时也同时进行上传，所以SEND_MESSAGE/创建假消息时需要把uploadID赋值为uploadID（开始识别文字时得到）
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.audiowithtext.recognition.and.upload"), case .data(_, let uploadId) = input.model.info.dateType {
            uploadID = uploadId
        }
        context.queue.async { [weak self] in
            guard let self = self else { return }
            var output = input
            let model = input.model
            let start = CACurrentMediaTime()
            if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
                chatId: model.chatId,
                threadId: model.threadId ?? "",
                rootId: input.rootId ?? "",
                parentId: input.parentId ?? "",
                type: .audio,
                content: content,
                uploadID: uploadID,
                cid: model.cid,
                position: input.context?.lastMessagePosition,
                client: client,
                context: input.context
            ) {
                input.stateHandler?(.getQuasiMessage(message, contextId: contextId))
                input.sendMessageTracker?.getQuasiMessage(msg: message,
                                                          context: input.context,
                                                          contextId: contextId,
                                                          size: nil,
                                                          rustCreateForSend: true,
                                                          rustCreateCost: CACurrentMediaTime() - start,
                                                          useNativeCreate: input.useNativeCreate)
                output.message = message
                output.extraInfo["cid"] = message.cid ?? ""
                self.accept(.success(output))
            } else {
                input.stateHandler?(.errorQuasiMessage)
                input.sendMessageTracker?.errorQuasiMessage(context: input.context)
                self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": model.cid ?? ""])))
            }
        }
    }
}
