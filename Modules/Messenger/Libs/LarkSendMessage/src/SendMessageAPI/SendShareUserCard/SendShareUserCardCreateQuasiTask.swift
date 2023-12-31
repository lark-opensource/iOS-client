//
//  SendShareUserCardCreateQuasiTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import FlowChart // FlowChartContext
import LarkSDKInterface // SDKRustService

public protocol SendShareUserCardCreateQuasiTaskContext: FlowChartContext {
    var client: SDKRustService { get }
}

public final class SendShareUserCardCreateQuasiTask
    <C: SendShareUserCardCreateQuasiTaskContext>: FlowChartTask<SendMessageProcessInput<SendShareUserCardModel>, SendMessageProcessInput<SendShareUserCardModel>, C> {
    override public var identify: String { "SendShareUserCardCreateQuasiTask" }

    public override func run(input: SendMessageProcessInput<SendShareUserCardModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let model = input.model
        var output = input

        var content = QuasiContent()
        content.shareChatterID = model.shareChatterId
        let sendToChatID: String
        let sendToThreadID: String

        switch model.sendChannelType {
        case .chat(let id):
            sendToChatID = id
            sendToThreadID = ""
        case .thread(let threadID, let chatID):
            sendToChatID = chatID
            sendToThreadID = threadID
        default:
            self.accept(.error(.dataError("sendChannelType nil", extraInfo: [:])))
            return
        }

        if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
            chatId: sendToChatID,
            threadId: sendToThreadID,
            rootId: sendToThreadID,
            parentId: sendToThreadID,
            type: .shareUserCard,
            content: content,
            client: client,
            createScene: model.createScene,
            context: input.context) {
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
