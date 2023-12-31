//
//  SendCardCreateQuasiTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import RustPB // Basic_V1_CardContent
import FlowChart // FlowChartContext
import LarkSDKInterface // SDKRustService

public protocol SendCardCreateQuasiTaskContext: FlowChartContext {
    var client: SDKRustService { get }
}

public final class SendCardCreateQuasiTask<C: SendCardCreateQuasiTaskContext>: FlowChartTask<SendMessageProcessInput<SendCardModel>, SendMessageProcessInput<SendCardModel>, C> {
    override public var identify: String { "SendCardCreateQuasiTask" }

    public override func run(input: SendMessageProcessInput<SendCardModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let model = input.model
        let card = model.card
        var output = input
        var content = QuasiContent()
        content.cardContent = RustPB.Basic_V1_CardContent()
        content.cardContent.type = card.type
        content.cardContent.richtext = card.richText
        content.cardContent.extra = card.extra
        content.cardContent.actions = card.actions

        if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
            chatId: model.chatId,
            threadId: model.threadId ?? "",
            rootId: input.rootId ?? "",
            parentId: input.parentId ?? "",
            type: .card,
            content: content,
            client: client,
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
