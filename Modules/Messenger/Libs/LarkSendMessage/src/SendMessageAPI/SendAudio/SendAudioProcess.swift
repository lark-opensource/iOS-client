//
//  SendAudioProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/7/29.
//

import Foundation
import RustPB // Basic_V1_QuasiContent

public enum AudioDataType {
    /// 语音+文字场景：之前语音数据Data是在SEND_MESSAGE时传给Rust进行上传；现在做了一个优化：识别文字时也同时进行上传，所以SEND_MESSAGE/创建假消息时需要把cid/uploadID赋值为uploadID（开始识别文字时得到）
    /// 优化文档：https://bytedance.feishu.cn/docx/B8x3dsbu7oEoXHx35jmcJjJ1nmf
    case data(_ data: Data, _ uploadID: String)
    /// 录音场景：录音时会边录边传，SEND_MESSAGE时只需要把uploadID传入即可，不需要再传语音数据Data
    case uploadID(_ id: String)
}

/// 方便发语音消息统一逻辑，把语音+文字、录音场景用一个模型封装
public struct NewAudioDataInfo {
    public enum AudioType {
        case pcm
        case opus
        case `default`
    }
    public var dateType: AudioDataType
    public var length: TimeInterval
    public var text: String?
    public var type: AudioType

    public init(dateType: AudioDataType,
                length: TimeInterval,
                type: AudioType,
                text: String? = nil) {
        self.dateType = dateType
        self.length = length
        self.type = type
        self.text = text
    }
}

/// 语音+文字场景
public struct AudioDataInfo {

    public enum AudioType {
        case pcm
        case opus
    }
    /// 之前语音数据Data是在SEND_MESSAGE时传给Rust进行上传
    public var data: Data
    public var length: TimeInterval
    public var text: String?
    public var type: AudioType
    /// 现在做了一个优化：识别文字时也同时进行上传，所以SEND_MESSAGE/创建假消息时需要把cid/uploadID赋值为uploadID（开始识别文字时得到）
    public var uploadID: String

    public init(data: Data,
                length: TimeInterval,
                type: AudioType,
                text: String? = nil,
                uploadID: String) {
        self.data = data
        self.length = length
        self.type = type
        self.text = text
        self.uploadID = uploadID
    }
}

/// 录音场景
public struct StreamAudioInfo {
    /// 录音时会边录边传，SEND_MESSAGE时只需要把uploadID传入即可，不需要再传语音数据Data
    public var uploadID: String
    public var length: TimeInterval
    public var text: String?

    public init(uploadID: String, length: TimeInterval, text: String? = nil) {
        self.uploadID = uploadID
        self.length = length
        self.text = text
    }
}

extension RustSendMessageAPI {
    func getSendAudioProcess() -> SerialProcess<SendMessageProcessInput<SendAudioModel>, RustSendMessageAPI> {
        let formatInputProcess = SerialProcess(SendAudioFormatInputTask(context: self), context: self)
        let nativeCreateAndSendProcess = SerialProcess(
            [SendAudioMsgOnScreenTask(context: self),
             SendMessageDealTask(context: self),
             SendAudioCreateQuasiMsgTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        let rustCreateAndSendProcess = SerialProcess(
            [SendAudioCreateQuasiMsgTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        return SerialProcess(
            [formatInputProcess,
             ConditionProcess(context: self) { [weak self] (input)  in
                 guard let self = self else { return nil }
                 var input = input
                 input.useNativeCreate = self.quasiMsgCreateByNative(context: input.context)
                 // 语音+文字场景：需要"端上创建假消息"优化
                 if case .data = input.model.info.dateType, input.useNativeCreate {
                     return (nativeCreateAndSendProcess, input)
                 } else {
                     input.useNativeCreate = false
                     return (rustCreateAndSendProcess, input)
                 }
             }],
        context: self)
    }
}

public struct SendAudioModel: SendMessageModelProtocol {
    var info: NewAudioDataInfo
    var chatId: String
    var threadId: String?
    var cid: String?
    var content: RustPB.Basic_V1_QuasiContent?
}

public protocol SendAudioProcessContext: SendAudioMsgOnScreenTaskContext,
                                         SendAudioFormatInputTaskContext {}

extension RustSendMessageAPI: SendAudioProcessContext {}
