//
//  InMeetParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/2/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewCommon

// MARK: - Construction
extension InMeetParticipantCellModel {
    // disable-lint: long function
    static func create(with participant: Participant,
                       userInfo: ParticipantUserInfo?,
                       meeting: InMeetMeeting,
                       hasCohostAuthority: Bool,
                       hostEnabled: Bool,
                       isDuplicated: Bool,
                       magicShareDocument: MagicShareDocument?,
                       forceMicState: MicIconState? = nil,
                       forceCameraImg: ParticipantImgKey? = nil) -> InMeetParticipantCellModel {
        let inMeetingInfo = meeting.data.inMeetingInfo
        let currentUser = meeting.account

        // 高亮效果
        let isSelf = currentUser == participant.user
        let isSelfSharingDocument = magicShareDocument?.user == currentUser
        let selectionStyle: UITableViewCell.SelectionStyle = isSelf || hasCohostAuthority || isSelfSharingDocument ? .default : .none
        // 头像
        let avatarInfo: AvatarInfo? = userInfo?.avatarInfo
        // 昵称
        let displayName: String? = userInfo?.name
        // 原始昵称（用于快捷电话邀请）
        let originalName: String? = userInfo?.originalName
        // 昵称小尾巴
        var nameTail: String?
        if isSelf {
            nameTail = " (\(I18n.View_M_Me))"
        } else if participant.isLarkGuest {
            if meeting.isInterviewMeeting {
                nameTail = I18n.View_G_CandidateBracket
            } else {
                nameTail = I18n.View_M_GuestParentheses
            }
        }
        // rooms会议室参会人人数
        var roomCountMessage: String?
        if participant.type == .room, let count = participant.settings.roomPeopleCnt {
            roomCountMessage = " \(I18n.View_G_RoomHasNumberPeople(count))"
        }
        // 申请发言
        let showMicHandsUp = participant.isMicHandsUp && (hasCohostAuthority || isSelf)
        /// 申请开摄像头
        let showCameraHandsUp = participant.isCameraHandsUp && (hasCohostAuthority || isSelf)
        /// 申请本地录制
        let showLocalRecordHandsUp = participant.isLocalRecordHandsUp && (hasCohostAuthority || isSelf)
        // 头像红点
        let showRedDot = showMicHandsUp || showCameraHandsUp || showLocalRecordHandsUp
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
        // 本地录制标识
        let showLocalRecordIcon = constructShowLocalRecordIcon(participant: participant)
        // 共享标识
        let showShareIcon = constructShowShareIcon(inMeetingInfo: inMeetingInfo, participant: participant)
        // 主持人标签
        let roleConfig = participant.roleConfig(hostEnabled: hostEnabled, isInterview: meeting.isInterviewMeeting)
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
        // 焦点视频
        let showFocus = constructShowFocus(inMeetingInfo: inMeetingInfo, participant: participant)
        // 状态表情举手
        let showStatusHandsUp = participant.settings.conditionEmojiInfo?.isHandsUp ?? false
        // 表情举手皮肤
        let handsUpEmojiKey = participant.settings.conditionEmojiInfo?.handsUpEmojiKey
        // 状态表情离开
        let showLeaveIcon = participant.settings.conditionEmojiInfo?.isStepUp ?? false
        // 系统电话标识
        let showSystemCallingStatus = participant.settings.mobileCallingStatus == .busy && !isSelf

        // 麦克风
        let micState: MicIconState
        if let forceMicState = forceMicState {
            micState = forceMicState
        } else {
            switch participant.settings.audioMode {
            case .noConnect:
                if isSelf, participant.settings.targetToJoinTogether == nil {
                    micState = .disconnected
                } else {
                    micState = .off()
                }
            case .internet, .unknown, .pstn:
                if isSelf {
                    let isMuted = meeting.microphone.isMuted
                    let microphoneEnable = !Privacy.audioDenied
                    switch (microphoneEnable, isMuted) {
                    case (false, _):
                        micState = .denied
                    case (true, true):
                        micState = .off()
                    case (true, false):
                        micState = .on()
                    }
                } else {
                    let micOff = participant.settings.isMicrophoneMutedOrUnavailable
                    micState = micOff ? .off() : .on()
                }
            }
        }
        // 摄像头
        var cameraImg: ParticipantImgKey = .empty
        if let forceCameraImg = forceCameraImg {
            cameraImg = forceCameraImg
        } else {
            if participant.type != .pstnUser {
                if isSelf {
                    let isMuted = meeting.camera.isMuted
                    let cameraEnable = !Privacy.videoDenied
                    switch (cameraEnable, isMuted) {
                    case (false, _):
                        cameraImg = .videoOffDisabled
                    case (true, true):
                        cameraImg = .videoOff
                    case (true, false):
                        cameraImg = .video
                    }
                } else {
                    let camOff = participant.settings.isCameraMutedOrUnavailable
                    cameraImg = camOff ? .videoOff : .video
                }
            }
        }
        let model = InMeetParticipantCellModel(selectionStyle: selectionStyle,
                                               avatarInfo: avatarInfo,
                                               showRedDot: showRedDot,
                                               displayName: displayName,
                                               originalName: originalName,
                                               nameTail: nameTail,
                                               roomCountMessage: roomCountMessage,
                                               showPstnIcon: showPstnIcon,
                                               deviceImg: deviceImgKey,
                                               showLocalRecordIcon: showLocalRecordIcon,
                                               showShareIcon: showShareIcon,
                                               showLeaveIcon: showLeaveIcon,
                                               roleConfig: roleConfig,
                                               interpretKey: interpretKey,
                                               userFlag: userFlag,
                                               showFocus: showFocus,
                                               showMicHandsUp: showMicHandsUp,
                                               showCameraHandsUp: showCameraHandsUp,
                                               showLocalRecordHandsUp: showLocalRecordHandsUp,
                                               micState: micState,
                                               cameraImg: cameraImg,
                                               participant: participant,
                                               volumeManager: meeting.volumeManager,
                                               showStatusHandsUp: showStatusHandsUp,
                                               handsUpEmojiKey: handsUpEmojiKey,
                                               showSystemCallingStatus: showSystemCallingStatus,
                                               service: meeting.service)
        return model
    }
    // enable-lint: long function
}

// MARK: - private
extension InMeetParticipantCellModel {

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

    /// 本地录制标识
    private static func constructShowLocalRecordIcon(participant: Participant) -> Bool {
        return participant.settings.localRecordSettings?.isLocalRecording == true
    }

    /// 共享标识
    private static func constructShowShareIcon(inMeetingInfo: VideoChatInMeetingInfo?, participant: Participant) -> Bool {
        let isUserSharingContent = inMeetingInfo?.checkIsUserSharingContent(with: participant.user) ?? false
        return isUserSharingContent
    }

    /// 焦点视频
    private static func constructShowFocus(inMeetingInfo: VideoChatInMeetingInfo?, participant: Participant) -> Bool {
        let focusingUser: ByteviewUser? = inMeetingInfo?.focusingUser
        let showFocus = focusingUser == participant.user
        return showFocus
    }
}

// MARK: - public
extension InMeetParticipantCellModel {

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
            // 该回调在主线程
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

// MARK: - ParticipantCellModelUpdate
extension InMeetParticipantCellModel: ParticipantCellModelUpdate {

    func updateRole(with meeting: InMeetMeeting) {
        roleConfig = participant.roleConfig(hostEnabled: meeting.setting.isHostEnabled, isInterview: meeting.isInterviewMeeting)
    }

    func updateShowShareIcon(with inMeetingInfo: VideoChatInMeetingInfo?) {
        showShareIcon = InMeetParticipantCellModel.constructShowShareIcon(inMeetingInfo: inMeetingInfo, participant: participant)
    }

    func updateShowFocus(with inMeetingInfo: VideoChatInMeetingInfo?) {
        showFocus = InMeetParticipantCellModel.constructShowFocus(inMeetingInfo: inMeetingInfo, participant: participant)
    }

    func updateDeviceImg(with duplicatedParticipantIds: Set<String>) {
        deviceImgKey = InMeetParticipantCellModel.constructDeviceImg(participant: participant, isDuplicated: duplicatedParticipantIds.contains(participant.user.id))
    }
}
