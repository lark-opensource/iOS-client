//
//  SendPostCreateQuasiTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import FlowChart // FlowChartContext
import LarkSDKInterface // SDKRustService
import RustPB

public protocol SendPostCreateQuasiTaskContext: FlowChartContext {
    var client: SDKRustService { get }
}

public final class SendPostCreateQuasiTask<C: SendPostCreateQuasiTaskContext>: FlowChartTask<SendMessageProcessInput<SendPostModel>, SendMessageProcessInput<SendPostModel>, C> {
    override public var identify: String { "SendPostCreateQuasiTask" }

    public override func run(input: SendMessageProcessInput<SendPostModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let model = input.model
        var output = input
        var quasiContent = QuasiContent()
        quasiContent.richText = model.content
        quasiContent.title = model.title
        quasiContent.isGroupAnnouncement = model.isGroupAnnouncement
        quasiContent.lingoOption = model.lingoInfo

        if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
            chatId: model.chatId,
            threadId: model.threadId ?? "",
            rootId: input.rootId ?? "",
            parentId: input.parentId ?? "",
            type: .post,
            content: quasiContent,
            client: client,
            scheduleTime: input.scheduleTime,
            transmitToChat: model.transmitToChat,
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
            // 视频先上屏，再转码。
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

// https://bytedance.feishu.cn/docx/Y3LYdRpEbos2zzx87KfcxyZonug
// 优化富文本视频上屏慢。从SendPostCreateQuasiTask中拆出转码部分，放在DealTask后，以实现先上屏再转码
public final class SendPostMsgWithMediaProcessTask<C: SendPostCreateQuasiTaskContext>: FlowChartTask<SendMessageProcessInput<SendPostModel>, SendMessageProcessInput<SendPostModel>, C> {
    override public var identify: String { "SendPostMsgWithMediaProcessTask" }

    public override func run(input: SendMessageProcessInput<SendPostModel>) {
        var output = input
        // 富文本中视频，消息未发送成功则设置为notWork。此时不可点击
        if let handler = input.model.preprocessingHandler {
            // 调用视频转码方法，转码完成到下一个task
            handler(input.message) { [weak self] processCost in
                output.processCost = processCost
                output.extraInfo["cid"] = input.message?.cid ?? ""
                self?.accept(.success(output))
            }
        } else {
            self.accept(.success(output))
        }
    }
}
