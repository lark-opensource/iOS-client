//
//  CalendarEventVideoMeetingChange.swift
//  ByteViewNetwork
//
//  Created by tuwenbo on 2022/9/26.
//

import Foundation
import RustPB

public struct CalendarEventVideoMeetingChangeData {
    public var infos: [RustPB.Calendar_V1_PushCalendarEventVideoMeetingChange.EventVideoMeetingInfo]
}

extension CalendarEventVideoMeetingChangeData: _NetworkDecodable, NetworkDecodable {

    typealias ProtobufType = RustPB.Calendar_V1_PushCalendarEventVideoMeetingChange

    init(pb: ProtobufType) {
        self.infos = pb.eventVideoMeetingInfo
    }
}
