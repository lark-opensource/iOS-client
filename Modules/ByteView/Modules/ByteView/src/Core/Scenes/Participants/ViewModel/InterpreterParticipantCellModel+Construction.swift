//
//  InterpreterParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/3/4.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

// MARK: ParticipantCellModelUpdate
extension InterpreterInMeetParticipantCellModel: ParticipantCellModelUpdate {

    func updateRole(with meeting: InMeetMeeting) {
        roleConfig = participant.roleConfig(hostEnabled: meeting.setting.isHostEnabled, isInterview: meeting.isInterviewMeeting)
    }
}

// MARK: - Construction InterpreterIdleParticipantCellModel
extension InterpreterIdleParticipantCellModel {

    static func create(with preInterpreter: SetInterpreter,
                       user: User,
                       meeting: InMeetMeeting) -> InterpreterIdleParticipantCellModel {
        // 头像
        let avatarInfo = user.avatarInfo
        // 头像红点
        let showRedDot = false
        // 昵称
        let displayName = user.displayName
        // 昵称小尾巴
        let nameTail: String? = nil
        // 入会状态
        let joinState: ParticipantJoinStateLabel.State = .idle
        // 设备标识
        let deviceImg: ParticipantImgKey = .empty
        // 主持人标签
        let roleConfig: ParticipantRoleConfig? = nil
        // 用户标签(外部)
        let isExternal = preInterpreterIsExtenal(user, byteviewUser: preInterpreter.user, local: meeting.myself)
        let userFlag: UserFlagType = isExternal ? .external : .none

        let model = InterpreterIdleParticipantCellModel(avatarInfo: avatarInfo,
                                                        showRedDot: showRedDot,
                                                        displayName: displayName,
                                                        nameTail: nameTail,
                                                        joinState: joinState,
                                                        deviceImg: deviceImg,
                                                        roleConfig: roleConfig,
                                                        userFlag: userFlag,
                                                        showMicHandsUp: false,
                                                        showCameraHandsUp: false,
                                                        showLocalRecordHandsUp: false,
                                                        idleInterpreter: preInterpreter,
                                                        userType: preInterpreter.user.type,
                                                        service: meeting.service)
        return model
    }

    private static func preInterpreterIsExtenal(_ user: User, byteviewUser: ByteviewUser, local: Participant?) -> Bool {
        guard let local = local else { return false }

        if user.id == local.identifier { // 本地用户
            return false
        }

        if local.tenantTag != .standard { // 自己是小 B 用户，则不关注 external
            return false
        }

        // 自己是Guest不展示外部标签
        if local.isLarkGuest || user.isRobot {
            return false
        }

        // 租户ID未知
        if user.tenantId == "" || user.tenantId == "-1" {
            return false
        }

        if byteviewUser.type == .larkUser || byteviewUser.type == .room || byteviewUser.type == .neoUser || byteviewUser.type == .neoGuestUser || byteviewUser.type == .standaloneVcUser {
            return user.tenantId != local.tenantId
        } else {
            return false
        }
    }
}

// MARK: - public
extension InterpreterParticipantCellModel {
    /// 拉取传译语言信息
    func getInterpretTag(_ callback: @escaping ((String?) -> Void)) {
        if let tag = interpret {
            callback(tag)
            return
        }
        guard let key = interpretKey, !key.isEmpty else {
            callback(nil)
            return
        }
        httpClient.i18n.get(key) { [weak self]  result in
            guard key == self?.interpretKey else { return } // 避免重用
            let language = result.value ?? ""
            let tag = I18n.View_G_InterpreterLanguage_Status(language)
            callback(tag)
            self?.interpret = tag
        }
    }
}
