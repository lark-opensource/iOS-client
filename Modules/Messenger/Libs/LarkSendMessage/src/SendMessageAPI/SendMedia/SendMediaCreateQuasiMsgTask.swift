//
//  SendMediaCreateQuasiMsgTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/16.
//

import UIKit
import Foundation
import FlowChart // FlowChartTask

public typealias SendMediaCreateQuasiMsgTaskContext = SendMediaMsgOnScreenTaskContext

public final class SendMediaCreateQuasiMsgTask<C: SendMediaCreateQuasiMsgTaskContext>: FlowChartTask<SendMessageProcessInput<SendMediaModel>, SendMessageProcessInput<SendMediaModel>, C> {
    override public var identify: String { "SendMediaCreateQuasiMsgTask" }

    public override func run(input: SendMessageProcessInput<SendMediaModel>) {
        var output = input
        guard let content = input.model.content, let client = flowContext?.client else {
            self.accept(.error(.dataError("content or client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        flowContext?.queue.async { [weak self] in
            guard let self = self else { return }
            let params = input.model.params
            let start = CACurrentMediaTime()
            if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
                chatId: params.chatID,
                threadId: params.threadID ?? "",
                rootId: input.rootId ?? "",
                parentId: input.parentId ?? "",
                type: .media,
                content: content,
                cid: input.model.cid,
                position: input.context?.lastMessagePosition,
                client: client,
                createScene: input.model.createScene,
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
                // 进行视频转码，processCost：转码耗时
                input.model.handler?(message) { [weak self] processCost in
                    output.message = message
                    output.extraInfo["cid"] = message.cid ?? ""
                    output.processCost = processCost
                    self?.accept(.success(output))
                }
            } else {
                input.stateHandler?(.errorQuasiMessage)
                input.sendMessageTracker?.errorQuasiMessage(context: input.context)
                self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": input.message?.cid ?? ""])))
            }
        }
    }
}
