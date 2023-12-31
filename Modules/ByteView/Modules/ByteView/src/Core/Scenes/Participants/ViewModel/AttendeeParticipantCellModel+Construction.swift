//
//  AttendeeParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/9/26.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

// MARK: - Construction
extension AttendeeParticipantCellModel {
    static func create(with participant: Participant,
                       userInfo: ParticipantUserInfo?,
                       meeting: InMeetMeeting,
                       hasCohostAuthority: Bool,
                       isDuplicated: Bool) -> AttendeeParticipantCellModel {
        // 高亮效果
        let selectionStyle: UITableViewCell.SelectionStyle = hasCohostAuthority ? .default : .none
        // 头像
        let avatarInfo: AvatarInfo? = userInfo?.avatarInfo
        // 昵称
        let displayName: String? = userInfo?.name
        // 原始昵称（用于快捷电话邀请）
        let originalName: String? = userInfo?.originalName
        // 昵称小尾巴
        var nameTail: String?
        let isSelf = meeting.account == participant.user
        if isSelf {
            nameTail = " (\(I18n.View_M_Me))"
        } else if participant.isLarkGuest {
            if meeting.isInterviewMeeting {
                nameTail = I18n.View_G_CandidateBracket
            } else {
                nameTail = I18n.View_M_GuestParentheses
            }
        }
        // 申请发言
        let showHandsUp = participant.isMicHandsUp && (hasCohostAuthority || isSelf)
        // 头像红点
        let showRedDot = showHandsUp
        // pstn标识
        var showPstnIcon: Bool = false
        if participant.type == .pstnUser, let pstn = participant.pstnInfo, ConveniencePSTN.isConvenience(pstn) {
            // 快捷电话邀请
            showPstnIcon = true
        } else if participant.type == .larkUser, participant.settings.audioMode == .pstn {
            // callme用户
            showPstnIcon = true
        }
        // 设备标识
        let deviceImgKey = constructDeviceImg(participant: participant, isDuplicated: isDuplicated)
        // 传译员标签
        var interpretKey: String?
        if let interpreterSetting = participant.settings.interpreterSetting,
           interpreterSetting.isUserConfirm,
           !interpreterSetting.interpretingLanguage.isMain {
            interpretKey = interpreterSetting.interpretingLanguage.despI18NKey
        }
        // 用户标签(外部)
        let isExternal = participant.isExternal(localParticipant: meeting.myself)
        let userFlag: UserFlagType = isExternal ? .external : .none
        // 状态表情举手
        let showStatusHandsUp = participant.settings.conditionEmojiInfo?.isHandsUp ?? false
        // 表情举手皮肤
        let handsUpEmojiKey = participant.settings.conditionEmojiInfo?.handsUpEmojiKey
        // 状态表情离开
        let showLeaveIcon = participant.settings.conditionEmojiInfo?.isStepUp ?? false
        // 麦克风
        let micState: MicIconState
        if participant.settings.isMicrophoneMuted {
            // 未开麦时隐藏
            micState = .hidden
        } else {
            switch participant.settings.audioMode {
            case .noConnect:
                if isSelf, participant.settings.targetToJoinTogether == nil {
                    micState = .disconnected
                } else {
                    micState = .off()
                }
            default:
                let disable = participant.settings.microphoneStatus != .normal
                micState = disable ? .off() : .on()
            }
        }
        let model = AttendeeParticipantCellModel(selectionStyle: selectionStyle,
                                                 avatarInfo: avatarInfo,
                                                 showRedDot: showRedDot,
                                                 displayName: displayName,
                                                 originalName: originalName,
                                                 nameTail: nameTail,
                                                 showPstnIcon: showPstnIcon,
                                                 deviceImg: deviceImgKey,
                                                 interpretKey: interpretKey,
                                                 userFlag: userFlag,
                                                 showHandsUp: showHandsUp,
                                                 showLeaveIcon: showLeaveIcon,
                                                 showStatusHandsUp: showStatusHandsUp,
                                                 handsUpEmojiKey: handsUpEmojiKey,
                                                 micState: micState,
                                                 participant: participant,
                                                 volumeManager: meeting.volumeManager,
                                                 service: meeting.service)
        return model
    }
}

// MARK: - public
extension AttendeeParticipantCellModel {

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

    /// 拉取昵称、头像等详细信息
    func getDetailInfo(_ callback: @escaping (() -> Void)) {
        if avatarInfo != nil, displayName != nil, originalName != nil {
            callback()
            return
        }
        httpClient.participantService.participantInfo(pid: participant, meetingId: participant.meetingId) { userInfo in
            // 回调在主线程
            guard userInfo.pid == self.participant.participantId else { return } // 避免重用
            // 头像
            let avatarInfo: AvatarInfo = userInfo.avatarInfo
            self.avatarInfo = avatarInfo
            // 昵称
            let displayName: String = userInfo.name
            self.displayName = displayName
            // 原始昵称（用于快捷电话邀请）
            let originalName: String = userInfo.originalName
            self.originalName = originalName
            callback()
        }
    }
}

// MARK: - Private
extension AttendeeParticipantCellModel {

    /// 设备标识
    private static func constructDeviceImg(participant: Participant, isDuplicated: Bool) -> ParticipantImgKey {
        var deviceImg: ParticipantImgKey = .empty
        if isDuplicated {
            switch participant.deviceType {
            case .mobile:
                deviceImg = .mobileDevice
            case .web:
                deviceImg = .webDevice
            default: break
            }
        }
        return deviceImg
    }
}

// MARK: - ParticipantCellModelUpdate
extension AttendeeParticipantCellModel: ParticipantCellModelUpdate {

    func updateDeviceImg(with duplicatedParticipantIds: Set<String>) {
        deviceImgKey = AttendeeParticipantCellModel.constructDeviceImg(participant: participant, isDuplicated: duplicatedParticipantIds.contains(participant.user.id))
    }
}
