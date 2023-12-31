//
//  CountdownSetting.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/23.
//

import Foundation

public struct CountdownSetting: Equatable {

    var isWebinarAttendee: Bool

    var hasCohostAuthority: Bool

    /// 操作权限生效条件：参会人个数超过阈值
    public var permissionThreshold: Int32

    public func canOperate(participantCount: @autoclosure () -> Int, isSharer: @autoclosure () -> Bool) -> (Bool, NoPermissonReason?) {
        if isWebinarAttendee { return (false, .webinarAttendee) }
        if participantCount() > permissionThreshold {
            return (hasCohostAuthority || isSharer(), .overCount(permissionThreshold))
        }
        return (true, nil)
    }

    public enum NoPermissonReason: Equatable {
        case webinarAttendee
        case overCount(Int32)
    }
}
