//
//  VideoMeeting.swift
//  Calendar
//
//  Created by heng zhu on 2019/5/22.
//

import Foundation
import CalendarFoundation
import RustPB

struct InstanceTime {
    let startTime: Int64
    let endTime: Int64
}

// 视频会议
public struct VideoMeeting: Equatable {

    typealias `Type` = Rust.VideoMeeting.VideoMeetingType

    var uniqueId: String { pb.uniqueID }
    var meetingNumber: String { pb.meetingNumber }
    var url: String { pb.meetingURL }
    var isExpired: Bool { pb.isExpired }
    var type: Type { pb.videoMeetingType }

    let pb: Rust.VideoMeeting

    init(pb: Rust.VideoMeeting) {
        self.pb = pb
    }

}

var CalendarVideoChatStatusClientRequestTime = "CalendarVideoChatStatusClientRequestTime"
extension Server.CalendarVideoChatStatus {
    var durationTime: Int {
        let requestTime = (clientRequestTime - (requestEndTime - requestBeginTime)) / 2000
        var duration = Int(meetingDuration / 1000) + Int(requestTime)
        if duration < 0 {
            duration = 0
        }
        return duration
    }

    var clientRequestTime: Int64 {
        get {
            return objc_getAssociatedObject(self, &CalendarVideoChatStatusClientRequestTime) as? Int64 ?? 0
        }
        set {
            objc_setAssociatedObject(self, &CalendarVideoChatStatusClientRequestTime, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
var AssociatedLiveStatusClientRequestTime = "AssociatedLiveStatusClientRequestTime"
extension Rust.AssociatedLiveStatus {
    var durationTime: Int {
        let requestTime = (clientRequestTime - (reqEndTime - reqBeginTime)) / 2000
        var duration = Int(liveDuration / 1000) + Int(requestTime)
        if duration < 0 {
            duration = 0
        }
        return duration
    }

    var clientRequestTime: Int64 {
        get {
            return objc_getAssociatedObject(self, &AssociatedLiveStatusClientRequestTime) as? Int64 ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedLiveStatusClientRequestTime, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
