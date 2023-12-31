//
//  SendCardProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import LarkModel // CardContent

extension RustSendMessageAPI {
    func getSendCardProcess() -> SerialProcess<SendMessageProcessInput<SendCardModel>, RustSendMessageAPI> {
        return SerialProcess(
            [SendMessageFormatInputTask(context: self),
             SendCardCreateQuasiTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
        context: self)
    }
}

public struct SendCardModel: SendMessageModelProtocol {
    var chatId: String
    var threadId: String?
    var cid: String?
    var card: LarkModel.CardContent
}

public protocol SendCardProcessContext: SendCardCreateQuasiTaskContext {}

extension RustSendMessageAPI: SendCardProcessContext {}
