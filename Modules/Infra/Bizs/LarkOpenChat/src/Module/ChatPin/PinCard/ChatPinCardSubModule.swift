//
//  ChatPinCardSubModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import RustPB
import LarkOpenIM

open class ChatPinCardSubModule: Module<ChatPinCardContext, ChatPinCardMetaModel> {
    open class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        assertionFailure("need override")
        return .unknown
    }

    public var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return Self.type
    }

    // 在拉取 Pin 数据前执行额外的预加载逻辑
    open func setup() {}

    // 解析 pin 数据
    open class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinCardContext) -> ChatPinPayload? {
        return nil
    }

    // 解析完所有 pin 数据后执行
    open func handleAfterParse(pinPayloads: [ChatPinPayload], extras: UniversalChatPinsExtras) {}
}
