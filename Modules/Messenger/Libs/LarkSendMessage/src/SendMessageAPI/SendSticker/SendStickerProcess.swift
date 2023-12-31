//
//  SendStickerProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/21.
//

import Foundation
import RustPB // Im_V1_Sticker

extension RustSendMessageAPI {
    func getSendStickerProcess() -> SerialProcess<SendMessageProcessInput<SendStickerModel>, RustSendMessageAPI> {
        return SerialProcess(
            [SendMessageFormatInputTask(context: self),
             SendStickerCreateQuasiMsgTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
        context: self)
    }
}

public struct SendStickerModel: SendMessageModelProtocol {
    var chatId: String
    var threadId: String?
    var cid: String?
    var sticker: RustPB.Im_V1_Sticker
}

public protocol SendStickerProcessContext: SendStickerCreateQuasiMsgContext {}

extension RustSendMessageAPI: SendStickerProcessContext {}
