//
//  ConveniencePSTNCheck.swift
//  ByteView
//
//  Created by wulv on 2021/11/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

enum PSTNCheckPriority: Int {
    case setting = 1
    case userType
    case userRole
    case userTenant
}

protocol ConveniencePSTNCheck {
    /// 优先级
    var priority: PSTNCheckPriority { get }
    /// 是否满足条件
    func checkEnable() -> (Bool, ConveniencePSTN.Error?)
    /// 错误信息
    var error: ConveniencePSTN.Error { get }
}

/// 是否有FG & AdminSettings & featureConfig配置权限
class ConveniencePSTNCheckSetting: ConveniencePSTNCheck {
    var priority: PSTNCheckPriority = .setting

    var error: ConveniencePSTN.Error {
        ConveniencePSTN.Error(description: "feature is disabled")
    }

    func checkEnable() -> (Bool, ConveniencePSTN.Error?) {
        if featureManager.isPstnQuickCallEnabled {
            return (true, nil)
        } else {
            return (false, error)
        }
    }

    let featureManager: MeetingSettingManager
    init(featureManager: MeetingSettingManager) {
        self.featureManager = featureManager
    }
}

/// 用户类型是否支持
class ConveniencePSTNCheckType: ConveniencePSTNCheck {
    var priority: PSTNCheckPriority = .userType

    var error: ConveniencePSTN.Error {
        ConveniencePSTN.Error(description: "target user type: \(targetUserType)")
    }

    func checkEnable() -> (Bool, ConveniencePSTN.Error?) {
        // 目前仅支持LarkUser，bot、飞书会议室、PSTN 电话参会方、SIP/H.323等不支持
        switch targetUserType {
        case .larkUser:
            return (true, nil)
        default:
            return (false, error)
        }
    }

    let targetUserType: ParticipantType
    init(targetUserType: ParticipantType) {
        self.targetUserType = targetUserType
    }
}

/// 用户租户是否支持
class ConveniencePSTNCheckTenant: ConveniencePSTNCheck {
    var priority: PSTNCheckPriority = .userTenant

    var error: ConveniencePSTN.Error {
        ConveniencePSTN.Error(description: "current user: \(localParticipant) , target user: \(targetParticipant), isCrossTenant: \(isCrossTenant)")
    }

    func checkEnable() -> (Bool, ConveniencePSTN.Error?) {
        // 暂不支持跨租户邀请
        guard meetingTenantId == localParticipant?.tenantId else {
            return (false, error)
        }
        var can: Bool = false
        if let isCrossTenant = isCrossTenant {
            can = !isCrossTenant
        } else if let local = localParticipant, let target = targetParticipant {
            if local.isLarkGuest || target.isLarkGuest {
                can = false
            } else if local.tenantTag != .standard || target.tenantTag != .standard {
                can = false
            } else {
                can = local.tenantId == target.tenantId
            }
        }

        if can {
            return (true, nil)
        } else {
            return (false, error)
        }
    }

    let targetParticipant: Participant?
    let localParticipant: Participant?
    let isCrossTenant: Bool?
    let meetingTenantId: String?

    init(isCrossTenant: Bool? = nil, targetParticipant: Participant? = nil, localParticipant: Participant? = nil, meetingTenantId: String?) {
        self.isCrossTenant = isCrossTenant
        self.targetParticipant = targetParticipant
        self.localParticipant = localParticipant
        self.meetingTenantId = meetingTenantId
    }
}

/// 用户角色是否支持
class ConveniencePSTNCheckRole: ConveniencePSTNCheck {
    var priority: PSTNCheckPriority = .userRole

    var error: ConveniencePSTN.Error {
        ConveniencePSTN.Error(description: "target user role: \(targetUserRole), meeting subType: \(meetingSubType)")
    }

    func checkEnable() -> (Bool, ConveniencePSTN.Error?) {
        // webinar 会议 观众暂不支持
        let isWebinarAttendee = meetingSubType == .webinar && targetUserRole == .webinarAttendee
        if isWebinarAttendee {
            return (false, error)
        } else {
            return (true, nil)
        }
    }

    let meetingSubType: MeetingSubType
    let targetUserRole: ParticipantMeetingRole
    init(meetingSubType: MeetingSubType, targetUserRole: ParticipantMeetingRole) {
        self.meetingSubType = meetingSubType
        self.targetUserRole = targetUserRole
    }
}
