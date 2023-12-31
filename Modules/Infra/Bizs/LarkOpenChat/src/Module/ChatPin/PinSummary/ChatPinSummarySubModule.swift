//
//  ChatPinSummarySubModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import RustPB
import LarkOpenIM

open class ChatPinSummarySubModule: Module<ChatPinSummaryContext, ChatPinSummaryMetaModel> {

    open class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        assertionFailure("need override")
        return .unknown
    }

    // 在拉取 Pin 数据前执行额外的预加载逻辑
    open func setup() {}

    // 解析 pin 数据
    open class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinSummaryContext) -> ChatPinPayload? {
        return nil
    }
}
