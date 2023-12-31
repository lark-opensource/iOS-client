//
//  SendGroupShareProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import RustPB // Basic_V1_CreateScene

extension RustSendMessageAPI {
    func getSendGroupShareProcess() -> SerialProcess<SendMessageProcessInput<SendGroupShareModel>, RustSendMessageAPI> {
        return SerialProcess(
            [SendMessageFormatInputTask(context: self),
             SendGroupShareCreateQuasiTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
        context: self)
    }
}

public struct SendGroupShareModel: SendMessageModelProtocol {
    var chatId: String
    var threadId: String?
    var cid: String?
    var shareChatId: String
    var createScene: Basic_V1_CreateScene?
}

public protocol SendGroupShareContext: SendGroupShareCreateQuasiTaskContext {}

extension RustSendMessageAPI: SendGroupShareContext {}
