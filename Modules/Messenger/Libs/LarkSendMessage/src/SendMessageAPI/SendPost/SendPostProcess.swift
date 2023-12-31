//
//  SendPostProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import RustPB // Basic_V1_RichText
import LarkModel

public struct SendPostParams {
    public var title: String
    public var content: RustPB.Basic_V1_RichText
    public var lingoInfo: RustPB.Basic_V1_LingoOption?
    public var parentMessage: LarkModel.Message?
    public var chatId: String
    public var threadId: String?
    public var isGroupAnnouncement: Bool
    public var scheduleTime: Int64?
    public var transmitToChat: Bool

    public init(title: String,
                content: RustPB.Basic_V1_RichText,
                lingoInfo: RustPB.Basic_V1_LingoOption? = nil,
                parentMessage: LarkModel.Message?,
                chatId: String,
                threadId: String?,
                isGroupAnnouncement: Bool,
                scheduleTime: Int64? = nil,
                transmitToChat: Bool = false) {
        self.title = title
        self.content = content
        self.lingoInfo = lingoInfo
        self.parentMessage = parentMessage
        self.chatId = chatId
        self.threadId = threadId
        self.isGroupAnnouncement = isGroupAnnouncement
        self.scheduleTime = scheduleTime
        self.transmitToChat = transmitToChat
    }
}

extension RustSendMessageAPI {
    func getSendPostProcess() -> SerialProcess<SendMessageProcessInput<SendPostModel>, RustSendMessageAPI> {
        let formatInputProcess = SerialProcess(SendMessageFormatInputTask<SendPostModel, RustSendMessageAPI>(context: self), context: self)

        // 定时发送
        let scheduleSendProcess = SerialProcess(
            [SendPostCreateQuasiTask(context: self),
             SendPostMsgWithMediaProcessTask(context: self),
             SendScheduleMsgTask(context: self)],
            context: self)

        let createAndSendProcess = SerialProcess(
            [SendPostCreateQuasiTask(context: self),
             SendMessageDealTask(context: self),
             SendPostMsgWithMediaProcessTask(context: self),
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
                 return (createAndSendProcess, input)
             }],
            context: self)
    }
}

public struct SendPostModel: SendMessageModelProtocol {
    var cid: String?
    var chatId: String
    var threadId: String?
    var title: String
    var content: RustPB.Basic_V1_RichText
    var lingoInfo: RustPB.Basic_V1_LingoOption
    var isGroupAnnouncement: Bool
    var preprocessingHandler: SendMessageAPI.PreprocessingHandler?
    /// Reply In tread发消息时，是否同时发送到群
    var transmitToChat: Bool = false
}

public protocol SendPostModelContext: SendPostCreateQuasiTaskContext {}

extension RustSendMessageAPI: SendPostModelContext {}
