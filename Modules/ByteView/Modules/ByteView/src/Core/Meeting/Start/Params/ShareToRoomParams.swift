//
//  ShareToRoomParams.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation
import ByteViewNetwork

struct ShareToRoomParams {
    let source: MeetingEntrySource
    let shareType: LocalShareType
    let entryCode: ShareContentEntryCodeType
    let url: String?
    let confirmSetting: ShareScreenToRoomRequest.ConfirmSetting?
    let whiteboardSetting: WhiteboardSettings?
}

extension ShareToRoomParams: CustomStringConvertible {
    var description: String {
        return """
            "ShareToRoomParams",
            "source: \(source)",
            "shareType: \(shareType)",
            "entryCode: \(entryCode)",
            "url.hash: \((url ?? "").hashValue)",
            "confirmSetting: \(confirmSetting)",
            "whiteboardSetting: \(whiteboardSetting)"
            """
    }
}
