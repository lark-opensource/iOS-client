//
//  SendLocationProcess.swift
//  LarkSDK
//
//  Created by ByteDance on 2022/8/5.
//

import UIKit
import Foundation
import LarkModel // LocationContent

extension RustSendMessageAPI {
    func getSendLocationProcess() -> SerialProcess<SendMessageProcessInput<SendLocationModel>, RustSendMessageAPI> {
        return SerialProcess(
            [SendMessageFormatInputTask(context: self),
             SendLocationCreateQuasiTask(context: self),
             SendMessageDealTask(context: self),
             SendMessageTask(context: self)],
        context: self)
    }
}

public struct SendLocationModel: SendMessageModelProtocol {
    var cid: String?
    var chatId: String
    var threadId: String?
    var screenShot: UIImage
    var location: LarkModel.LocationContent
}

public protocol SendLocationProcessContext: SendLocationCreateQuasiTaskContext {}

extension RustSendMessageAPI: SendLocationProcessContext {}
