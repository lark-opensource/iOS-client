//
//  SendFileByRustSubProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/8.
//

import UIKit
import Foundation
import FlowChart // FlowChartTask

public typealias SendFileCreateQuasiMsgTaskContext = SendFileMsgOnScreenTaskContext

// rust发文件
public final class SendFileCreateQuasiMsgTask<C: SendFileCreateQuasiMsgTaskContext>: FlowChartTask<SendMessageProcessInput<SendFileModel>, SendMessageProcessInput<SendFileModel>, C> {
    override public var identify: String { "SendFileCreateQuasiMsgTask" }

    public override func run(input: SendMessageProcessInput<SendFileModel>) {
        guard let client = flowContext?.client, let content = input.model.content else {
            self.accept(.error(.dataError("client or content is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        flowContext?.queue.async { [weak self] in
            guard let self = self else { return }
            var output = input
            let model = input.model
            let start = CACurrentMediaTime()
            let sendToThread = !model.threadId.isNil
            if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
                chatId: model.chatId,
                threadId: model.threadId ?? "",
                rootId: sendToThread ? model.threadId ?? "" : input.rootId ?? "",
                parentId: sendToThread ? model.threadId ?? "" : input.parentId ?? "",
                type: .file,
                content: content,
                cid: input.model.cid,
                position: input.context?.lastMessagePosition,
                client: client,
                createScene: model.createScene,
                context: input.context
            ) {
                input.stateHandler?(.getQuasiMessage(message, contextId: contextId, processCost: model.size, rustCreateForSend: true, rustCreateCost: (CACurrentMediaTime() - start)))
                input.sendMessageTracker?.getQuasiMessage(msg: message,
                                                          context: input.context,
                                                          contextId: contextId,
                                                          size: model.size,
                                                          rustCreateForSend: true,
                                                          rustCreateCost: CACurrentMediaTime() - start,
                                                          useNativeCreate: input.useNativeCreate)
                self.flowContext?.addPendingMessages(id: message.cid, value: (message: message, filePath: model.path, deleteFileWhenFinish: model.removeOriginalFileAfterFinish))
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
