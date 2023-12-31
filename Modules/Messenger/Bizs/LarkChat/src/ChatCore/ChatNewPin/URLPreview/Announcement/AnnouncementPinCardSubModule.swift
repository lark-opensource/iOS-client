//
//  AnnouncementPinCardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/24.
//

import Foundation
import LarkOpenChat
import RustPB
import LarkModel
import DynamicURLComponent

public final class AnnouncementPinCardSubModule: URLPreviewBasePinCardSubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .announcementPin
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinCardContext) -> ChatPinPayload? {
        guard case .announcementPin(let announcementPinData) = pb else {
            return nil
        }
        var payload = AnnouncementChatPinPayload(useOpendoc: announcementPinData.useOpendoc, url: announcementPinData.url, hangPoint: announcementPinData.urlPreviewHangPoint)
        if let entityPB = extras.previewEntities[payload.hangPoint.previewID] {
            payload.urlPreviewEntity = URLPreviewEntity.transform(from: entityPB)
        }
        return payload
    }

}
