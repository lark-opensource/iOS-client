//
//  SendFileProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/7/29.
//

import Foundation
import RustPB // Basic_V1_CreateScene

extension RustSendMessageAPI {
    func getSendFileProcess() -> SerialProcess<SendMessageProcessInput<SendFileModel>, RustSendMessageAPI> {
        let formatInputProcess = SerialProcess(SendFileFormatInputTask(context: self), context: self)

        let nativeCreateAndSendProcess = SerialProcess(
            [SendFileMsgOnScreenTask(context: self),
             SendMessageDealTask(context: self),
             SendFileCreateQuasiMsgTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        let rustCreateAndSendProcess = SerialProcess(
            [SendFileCreateQuasiMsgTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        return SerialProcess(
            [formatInputProcess,
             ConditionProcess(context: self) { [weak self] (input)  in
                 guard let self = self else { return nil }
                 var input = input
                 input.useNativeCreate = self.quasiMsgCreateByNative(context: input.context)
                 if input.useNativeCreate {
                     return (nativeCreateAndSendProcess, input)
                 }
                 return (rustCreateAndSendProcess, input)
             }],
        context: self)
    }
}

public struct SendFileModel: SendMessageModelProtocol {
    var path: String
    var name: String
    var chatId: String
    var threadId: String?
    var cid: String?
    var size: Int64?
    var content: QuasiContent?
    var removeOriginalFileAfterFinish: Bool
    // 是否执行beforeCreateQuasi回调
    var executeBeforeCreateQuasiCallback: Bool = true
    var createScene: Basic_V1_CreateScene?
}

public protocol SendFileProcessContext: SendFileMsgOnScreenTaskContext,
                                        SendFileFormatInputTaskContext {}

extension RustSendMessageAPI: SendFileProcessContext {}
