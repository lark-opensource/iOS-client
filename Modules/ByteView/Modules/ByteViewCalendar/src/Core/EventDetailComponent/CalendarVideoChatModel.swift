//
//  CalendarVideoChatModel.swift
//  ByteViewMod
//
//  Created by tuwenbo on 2022/9/21.
//

import Foundation
import RustPB
import UniverseDesignIcon


// 视频会议
public struct VideoMeeting: Equatable {

    var uniqueId: String { pb.uniqueID }
    var meetingNumber: String { pb.meetingNumber }
    var url: String { pb.meetingURL }
    var isExpired: Bool { pb.isExpired }
    var type: Rust.VideoMeeting.VideoMeetingType { pb.videoMeetingType }

    let pb: Rust.VideoMeeting

    init(pb: Rust.VideoMeeting) {
        self.pb = pb
    }

}

extension Server.CalendarVideoChatStatus {
    private static var calendarVideoChatStatusClientRequestTime = "CalendarVideoChatStatusClientRequestTime"
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
            return objc_getAssociatedObject(self, &Self.calendarVideoChatStatusClientRequestTime) as? Int64 ?? 0
        }
        set {
            objc_setAssociatedObject(self, &Self.calendarVideoChatStatusClientRequestTime, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}


extension Rust.VideoMeeting {
    var videoMeetingIconType: Rust.VideoMeetingIconType {
        if case .larkLiveHost = videoMeetingType {
            return .live
        }
        if case .other = videoMeetingType {
            if case .otherConfigs(let otherVideoMeetingConfig) = customizedConfigs {
                if case .live = otherVideoMeetingConfig.icon {
                    return .live
                } else {
                    return .videoMeeting
                }
            }
        }
        return .videoMeeting
    }

    func isEqual(to model: Rust.VideoMeeting) -> Bool {
        if videoMeetingType != model.videoMeetingType {
            return false
        }

        if meetingURL != model.meetingURL {
            return false
        }

        if case .otherConfigs(let configs) = customizedConfigs,
           case .otherConfigs(let toConfigs) = model.customizedConfigs {
            if configs.icon != toConfigs.icon {
                return false
            }

            if configs.customizedDescription != configs.customizedDescription {
                return false
            }
        }

        return true
    }
}

extension Rust.VideoMeetingIconType {
    var iconNormal: UIImage {
        switch self {
        case .live:
            return UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).renderColor(with: .n3)
        @unknown default:
            return UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)
        }
    }

    var iconGary: UIImage {
        switch self {
        case .live:
            return UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).renderColor(with: .n3)
        @unknown default:
            return UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)
        }
    }

    var iconGreen: UIImage {
        switch self {
        case .live:
            return UDIcon.getIconByKeyNoLimitSize(.livestreamFilled).ud.withTintColor(UIColor.ud.colorfulGreen)
        @unknown default:
            return UDIcon.getIconByKeyNoLimitSize(.videoFilled).ud.withTintColor(UIColor.ud.functionSuccessFillDefault)
        }
    }
}
