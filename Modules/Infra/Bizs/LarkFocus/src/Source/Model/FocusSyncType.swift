//
//  FocusSyncType.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/11.
//

import Foundation
import RustPB

/// 个人状态的同步设置（是否由请假、会议自动同步开启相应个人状态）
///
/// ```
/// enum FocusSyncType: Int {
///     case isSynOnLeave  = 1
///     case isSynMeeting  = 2
///     case isSynSchedule = 3
/// }
/// ```
public typealias FocusSyncType = Contact_V1_CustomStatusSyncField

public extension FocusSyncType {

    /// 每种同步设置所对应的个人状态类型
    var relatedFocusType: UserFocusType {
        switch self {
        case .isSynOnLeave:     return .onLeave
        case .isSynMeeting:     return .inMeeting
        case .isSynSchedule:    return .inMeeting
        @unknown default:       return .unknown
        }
    }
}
