//
//  UnknownPinSummarySubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/4.
//

import Foundation
import LarkOpenChat
import RustPB

public final class UnknownPinSummarySubModule: ChatPinSummarySubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .unknown
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinSummaryContext) -> ChatPinPayload? {
        guard case .unknown(let unknownData) = pb else {
            return nil
        }
        return UnknownChatPinPayload(title: unknownData.title, icon: unknownData.icon)
    }
}
