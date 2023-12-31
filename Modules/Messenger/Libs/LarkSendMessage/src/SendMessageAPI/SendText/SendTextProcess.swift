//
//  SendTextProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/7/29.
//

import Foundation
import RustPB // Basic_V1_RichText
import LarkModel

public struct SendTextParams {
    public var content: RustPB.Basic_V1_RichText
    public var lingoInfo: RustPB.Basic_V1_LingoOption?
    public var parentMessage: LarkModel.Message?
    public var chatId: String
    public var threadId: String?
    public var createScene: Basic_V1_CreateScene?
    public var scheduleTime: Int64?
    public var transmitToChat: Bool

    public init(content: RustPB.Basic_V1_RichText,
                lingoInfo: RustPB.Basic_V1_LingoOption? = nil,
                parentMessage: LarkModel.Message?,
                chatId: String,
                threadId: String?,
                createScene: Basic_V1_CreateScene? = nil,
                scheduleTime: Int64? = nil,
                transmitToChat: Bool = false) {
        self.content = content
        self.lingoInfo = lingoInfo
        self.parentMessage = parentMessage
        self.chatId = chatId
        self.threadId = threadId
        self.createScene = createScene
        self.scheduleTime = scheduleTime
        self.transmitToChat = transmitToChat
    }
}

extension RustSendMessageAPI {
    func getSendTextProcess() -> SerialProcess<SendMessageProcessInput<SendTextModel>, RustSendMessageAPI> {
        let formatInputProcess = SerialProcess(SendTextFormatInputTask(context: self), context: self)

        let scheduleSendProcess = SerialProcess(
            [SendTextCreateQuasiMsgTask(context: self),
             SendScheduleMsgTask(context: self)],
            context: self)

        let nativeCreateAndSendProcess = SerialProcess(
            [SendTextMsgOnScreenTask(context: self),
             SendMessageDealTask(context: self),
             SendTextCreateQuasiMsgTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        let rustCreateAndSendProcess = SerialProcess(
            [SendTextCreateQuasiMsgTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        return SerialProcess(
            [formatInputProcess,
             ConditionProcess(context: self) { [weak self] (input)  in
                 guard let self = self else { return nil }
                 var input = input
                 if let time = input.scheduleTime {
                     return (scheduleSendProcess, input)
                 }
                 input.useNativeCreate = self.quasiMsgCreateByNative(context: input.context)
                 switch RustSendMessageModule.genCreateQuasiMsgType(input) {
                 case .native:
                     return (nativeCreateAndSendProcess, input)
                 case .rust:
                     input.useNativeCreate = false
                     return (rustCreateAndSendProcess, input)
                 }
             }],
        context: self)
    }
}

public struct SendTextModel: SendMessageModelProtocol {
    var content: RustPB.Basic_V1_RichText
    var lingoInfo: RustPB.Basic_V1_LingoOption
    var quasiContent: QuasiContent?
    var cid: String?
    var chatId: String
    var threadId: String?
    var createScene: Basic_V1_CreateScene?
    /// Reply In tread发消息时，是否同时发送到群
    var transmitToChat: Bool = false
}

public protocol SendTextProcessContext: SendTextMsgOnScreenTaskContext,
                                        SendTextFormatInputTaskContext {}

extension RustSendMessageAPI: SendTextProcessContext {}
