//
//  SendGroupShareCreateQuasiTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import FlowChart // FlowChartContext
import LarkSDKInterface // SDKRustService

public protocol SendGroupShareCreateQuasiTaskContext: FlowChartContext {
    var client: SDKRustService { get }
}

public final class SendGroupShareCreateQuasiTask
    <C: SendGroupShareCreateQuasiTaskContext>: FlowChartTask<SendMessageProcessInput<SendGroupShareModel>, SendMessageProcessInput<SendGroupShareModel>, C> {
    override public var identify: String { "SendGroupShareCreateQuasiTask" }

    public override func run(input: SendMessageProcessInput<SendGroupShareModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let model = input.model
        var output = input
        let sendToThread = !model.threadId.isNil

        var content = QuasiContent()
        content.shareChatID = model.shareChatId

        if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
            chatId: model.chatId,
            threadId: model.threadId ?? "",
            rootId: sendToThread ? model.threadId ?? "" : input.rootId ?? "",
            parentId: sendToThread ? model.threadId ?? "" : input.parentId ?? "",
            type: .shareGroupChat,
            content: content,
            client: client,
            createScene: input.model.createScene,
            context: input.context
        ) {
            input.stateHandler?(.getQuasiMessage(message, contextId: contextId))
            input.sendMessageTracker?.getQuasiMessage(msg: message,
                                                      context: input.context,
                                                      contextId: contextId,
                                                      size: nil,
                                                      rustCreateForSend: nil,
                                                      rustCreateCost: nil,
                                                      useNativeCreate: false)
            output.message = message
            output.extraInfo["cid"] = message.cid ?? ""
            self.accept(.success(output))
        } else {
            input.stateHandler?(.errorQuasiMessage)
            input.sendMessageTracker?.errorQuasiMessage(context: input.context)
            self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": input.model.cid ?? ""])))
        }
    }
}
