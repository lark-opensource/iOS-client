//
// Created by liujianlong on 2022/9/19.
//

import Foundation

public struct WebinarAttendeePermission: Equatable {
    public var allowIm: Bool
    public var allowChangeName: Bool
    public var allowHandsUp: Bool
}

/// webinar 彩排状态
public enum WebinarRehearsalStatusType: Int {
    /// 关闭
    case unknown = 0
    /// 开启
    case on = 1
    /// 结束
    case end = 2
}

public struct WebinarSettings: Equatable {
    public var attendeePermission: WebinarAttendeePermission?
    public var maxAttendeeNum: Int32?
    public var rehearsalStatus: WebinarRehearsalStatusType?
    public init(attendeePermission: WebinarAttendeePermission?,
                maxAttendeeNum: Int32?,
                rehearsalStatus: WebinarRehearsalStatusType?) {
        self.attendeePermission = attendeePermission
        self.maxAttendeeNum = maxAttendeeNum
        self.rehearsalStatus = rehearsalStatus
    }
}

extension WebinarSettings {
    var pbType: PBWebinarSettings {
        var settings = PBWebinarSettings()
        if let permission = attendeePermission {
            settings.attendeePermission = permission.pbType
        }
        if let maxAttendeeNum = maxAttendeeNum {
            settings.maxAttendeeNum = maxAttendeeNum
        }
        if let status = self.rehearsalStatus,
           let pbRehearsalStatus = PBWebinarRehearsalStatusType(rawValue: status.rawValue) {
            settings.rehearsalStatus = pbRehearsalStatus
        }
        return settings
    }
}

extension WebinarAttendeePermission {
    var pbType: PBWebinarAttendeePermission {
        var permission = PBWebinarAttendeePermission()
        permission.allowIm = allowIm
        permission.allowChangeName = allowChangeName
        permission.allowHandsUp = allowHandsUp
        return permission
    }
}
