//
//  AnnouncementPinSummarySubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/24.
//

import Foundation
import LarkOpenChat
import RustPB

public final class AnnouncementPinSummarySubModule: ChatPinSummarySubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .announcementPin
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinSummaryContext) -> ChatPinPayload? {
        guard case .announcementPin(let announcementPinData) = pb else {
            return nil
        }
        return AnnouncementChatPinPayload(useOpendoc: announcementPinData.useOpendoc,
                                          url: announcementPinData.url,
                                          hangPoint: announcementPinData.urlPreviewHangPoint,
                                          announcementPBModel: extras.announcement)
    }
}
