//
//  SendStickerCreateQuasiMsgTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import FlowChart // FlowChartTask
import LarkSDKInterface // SDKRustService

public final class SendStickerCreateQuasiMsgTask<C: SendStickerCreateQuasiMsgContext>: FlowChartTask<SendMessageProcessInput<SendStickerModel>, SendMessageProcessInput<SendStickerModel>, C> {
    override public var identify: String { "SendStickerCreateQuasiMsgTask" }

    public override func run(input: SendMessageProcessInput<SendStickerModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("content or client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let sticker = input.model.sticker
        let model = input.model
        var output = input
        flowContext?.queue.async { [weak self] in
            guard let self = self else { return }
            var content = QuasiContent()
            content.key = sticker.image.origin.key
            content.width = sticker.image.origin.width
            content.height = sticker.image.origin.height
            content.stickerSetID = sticker.stickerSetID
            content.stickerID = sticker.stickerID

            if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
                chatId: model.chatId,
                threadId: model.threadId ?? "",
                rootId: input.rootId ?? "",
                parentId: input.parentId ?? "",
                type: .sticker,
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
                input.sendMessageTracker?.errorQuasiMessage(context: input.context)
                self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": model.cid ?? ""])))
            }
        }
    }
}

public protocol SendStickerCreateQuasiMsgContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
}
