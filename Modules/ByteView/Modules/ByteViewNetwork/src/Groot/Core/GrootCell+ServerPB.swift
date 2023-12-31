//
//  GrootCell+ServerPB.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2023/3/14.
//

import Foundation
import ServerPB

typealias ServerPBMeetingMeta = ServerPB_Videochat_common_MeetingMeta

extension MeetingMeta {
    var spbType: ServerPBMeetingMeta {
        var meta = ServerPBMeetingMeta()
        meta.meetingID = meetingID
        if let breakoutRoomID = breakoutRoomID,
           !breakoutRoomID.isEmpty {
            meta.breakoutRoomID = breakoutRoomID
            meta.metaType = .breakoutRoom
        } else {
            meta.metaType = .meeting
        }
        return meta
    }
}
