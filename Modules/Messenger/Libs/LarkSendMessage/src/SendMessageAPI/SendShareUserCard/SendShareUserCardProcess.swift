//
//  SendShareUserCardProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import RustPB // Basic_V1_CreateScene

extension RustSendMessageAPI {
    func getSendShareUserCardProcess() -> SerialProcess<SendMessageProcessInput<SendShareUserCardModel>, RustSendMessageAPI> {
        return SerialProcess(
            [SendMessageFormatInputTask(context: self),
             SendShareUserCardCreateQuasiTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
        context: self)
    }
}

public enum SendChannelType {
    case chat(id: String)
    case thread(threadID: String, chatID: String)
    case unknown
}

public struct SendShareUserCardModel: SendMessageModelProtocol {
    var cid: String?
    var shareChatterId: String
    var sendChannelType: SendChannelType
    var createScene: Basic_V1_CreateScene?
}

public protocol SendShareUserCardProcessContext: SendShareUserCardCreateQuasiTaskContext {}

extension RustSendMessageAPI: SendShareUserCardProcessContext {}
