//
//  SendTextCreateQuasiMsgTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/21.
//

import UIKit
import Foundation
import FlowChart // FlowChartTask

public typealias SendTextCreateQuasiMsgTaskContext = SendTextMsgOnScreenTaskContext

// Rust创建文本消息
public final class SendTextCreateQuasiMsgTask<C: SendTextCreateQuasiMsgTaskContext>: FlowChartTask<SendMessageProcessInput<SendTextModel>, SendMessageProcessInput<SendTextModel>, C> {
    override public var identify: String { "SendTextCreateQuasiMsgTask" }

    public override func run(input: SendMessageProcessInput<SendTextModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        flowContext?.queue.async { [weak self] in
            guard let self = self else { return }
            var quasiContent: QuasiContent
            // 如果端上创建过假消息，则可以直接使用
            if let content = input.model.quasiContent {
                quasiContent = content
            } else {
                let content = input.model.content.trimCharacters(in: .whitespacesAndNewlines, postion: .tail)
                quasiContent = QuasiContent()
                quasiContent.richText = content
                quasiContent.lingoOption = input.model.lingoInfo
            }
            var output = input
            let model = input.model
            let sendToThread = !model.threadId.isNil
            let start = CACurrentMediaTime()
            if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
                chatId: model.chatId,
                threadId: model.threadId ?? "",
                rootId: sendToThread ? model.threadId ?? "" : input.rootId ?? "",
                parentId: sendToThread ? model.threadId ?? "" : input.parentId ?? "",
                type: .text,
                content: quasiContent,
                cid: model.cid,
                position: input.context?.lastMessagePosition,
                client: client,
                scheduleTime: input.scheduleTime,
                transmitToChat: model.transmitToChat,
                createScene: model.createScene,
                context: input.context
            ) {
                input.stateHandler?(.getQuasiMessage(message, contextId: contextId, rustCreateForSend: true, rustCreateCost: (CACurrentMediaTime() - start)))
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
                self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": input.message?.cid ?? ""])))
            }
        }
    }
}
