//
//  AnnouncementChatPinPayload.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/24.
//

import Foundation
import LarkOpenChat
import RustPB
import LarkModel
import TangramService

struct AnnouncementChatPinPayload: ChatPinPayload {
    let useOpendoc: Bool
    let url: String
    let hangPoint: RustPB.Basic_V1_PreviewHangPoint
    var urlPreviewEntity: URLPreviewEntity?
    var announcementPBModel: Basic_V1_Chat.Announcement?
}

extension AnnouncementChatPinPayload: URLPreviewChatPinModel {}
