//
//  SendTextMsgOnScreenTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/21.
//

import UIKit
import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import LarkModel // Chatter
import FlowChart // FlowChartContext
import LarkSDKInterface // SDKRustService
import LarkAIInfra // MyAIChatModeConfig

public protocol SendTextMsgOnScreenTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var currentChatter: Chatter { get }
    func randomString(length: Int) -> String
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
}

// native发文本
public final class SendTextMsgOnScreenTask<C: SendTextMsgOnScreenTaskContext>: FlowChartTask<SendMessageProcessInput<SendTextModel>, SendMessageProcessInput<SendTextModel>, C> {
    override public var identify: String { "SendTextMsgOnScreenTask" }

    public override func run(input: SendMessageProcessInput<SendTextModel>) {
        guard let currentChatter = flowContext?.currentChatter else {
            self.accept(.error(.dataError("content or chatter is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var output = input
        let model = input.model

        let position = input.context?.lastMessagePosition
        let cid = flowContext?.randomString(length: 10) ?? ""
        let createTime = CACurrentMediaTime()
        let content = input.model.content.trimCharacters(in: .whitespacesAndNewlines, postion: .tail)
        var quasiContent = QuasiContent()
        quasiContent.richText = content
        quasiContent.lingoOption = model.lingoInfo
        let quasiMessage = SendTextMsgOnScreenTask.createTextMessageByNative(context: input.context,
                                                                             quasiContent: quasiContent,
                                                                             currentChatter: currentChatter,
                                                                             cid: cid,
                                                                             rootId: input.rootId ?? "",
                                                                             lastMessagePosition: position,
                                                                             chatId: model.chatId,
                                                                             parentId: input.parentId ?? "",
                                                                             displayMode: input.context?.chatDisplayMode)
        // threadId有值：话题群 + replyInThread；position = -3：replyInThread，此if：只排除话题群场景
        if quasiMessage.threadId.isEmpty || quasiMessage.position == replyInThreadMessagePosition {
            // 当前网络还可以，端上创建的假消息上屏不需要展示loading
            if let netStatus = self.flowContext?.currentNetStatus, (netStatus == .excellent || netStatus == .evaluating) {
                quasiMessage.localStatus = .fakeSuccess
            }
        }
        let contextId = input.context?.contextID ?? ""
        input.stateHandler?(.getQuasiMessage(quasiMessage, contextId: contextId))
        input.sendMessageTracker?.getQuasiMessage(msg: quasiMessage,
                                                  context: input.context,
                                                  contextId: contextId,
                                                  size: nil,
                                                  rustCreateForSend: nil,
                                                  rustCreateCost: nil,
                                                  useNativeCreate: input.useNativeCreate)
        RustSendMessageAPI.logger.info("native create quasiMessage cost \(CACurrentMediaTime() - createTime) cid = \(model.cid) ")
        output.message = quasiMessage
        output.model.cid = cid
        output.extraInfo["cid"] = cid
        output.model.quasiContent = quasiContent
        self.accept(.success(output))
    }

    //本地创建textMessage
    private static func createTextMessageByNative(context: APIContext?,
                                                 quasiContent: RustPB.Basic_V1_QuasiContent,
                                                 currentChatter: Chatter,
                                                 cid: String,
                                                 rootId: String,
                                                 lastMessagePosition: Int32? = nil,
                                                 chatId: String,
                                                 parentId: String,
                                                 displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum?) -> LarkModel.Message {
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = chatId
        channelPb.type = .chat

        let time = Date().timeIntervalSince1970

        let textContent = TextContent(
            text: quasiContent.text,
            previewUrls: [],
            richText: quasiContent.richText,
            docEntity: nil,
            abbreviation: nil,
            typedElementRefs: nil
        )
        let quasiMessage = LarkModel.Message.transform(pb: Message.PBModel())
        quasiMessage.cid = cid
        quasiMessage.id = cid
        quasiMessage.type = .text
        quasiMessage.channel = channelPb
        quasiMessage.createTime = time
        quasiMessage.createTimeMs = Int64(time) * 1000
        quasiMessage.updateTime = time
        quasiMessage.rootId = rootId
        quasiMessage.parentId = parentId
        quasiMessage.fromId = currentChatter.id
        quasiMessage.position = lastMessagePosition ?? 0
        quasiMessage.meRead = true
        quasiMessage.fromType = .user
        quasiMessage.content = textContent
        quasiMessage.sourceType = .typeFromMessage
        quasiMessage.isBadged = true
        quasiMessage.displayMode = displayMode?.transform() ?? .default
        quasiMessage.fromChatter = currentChatter
        quasiMessage.localStatus = .process
        if let partialReplyInfo: PartialReplyInfo? = context?.get(key: APIContext.partialReplyInfo) {
            quasiMessage.partialReplyInfo = partialReplyInfo
        }
        return quasiMessage
    }
}
