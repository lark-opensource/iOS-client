//
//  SearchParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

// MARK: - Construction
extension SearchParticipantCellModel {

    enum FromType {
        case participant
        case interpret
        case commonSearch
    }

    // disable-lint: long function
    static func create(with searchBox: ParticipantSearchBox,
                       meeting: InMeetMeeting,
                       hasCohostAuthority: Bool,
                       hostEnabled: Bool,
                       meetingSubType: MeetingSubType,
                       duplicatedParticipantIds: Set<String>,
                       magicShareDocument: MagicShareDocument? = nil,
                       from: FromType = .participant) -> SearchParticipantCellModel {
        let inMeetingInfo = meeting.data.inMeetingInfo

        // 是否支持快捷电话邀请
        let enableInvitePSTN = constructEnableInvitePSTN(searchBox: searchBox, localParticipant: meeting.myself,
                                                         featureManager: meeting.setting, meetingTenantId: meeting.info.tenantId, meetingSubType: meetingSubType)
        // 高亮效果
        let selectionStyle = constructSelectionStyle(from: from, searchBox: searchBox,
                                                     hasHostCohostAuthority: hasCohostAuthority, currentUser: meeting.account,
                                                     magicShareDocument: magicShareDocument, enableInvitePSTN: enableInvitePSTN)
        // 头像
        var avatarInfo: AvatarInfo = .asset(nil)
        if let userInfo = searchBox.userInfo {
            avatarInfo = userInfo.avatarInfo
        } else if let userItem = searchBox.userItem {
            avatarInfo = userItem.avatarInfo
        } else if let roomItem = searchBox.roomItem {
            avatarInfo = roomItem.avatarInfo
        }
        // room会中动画
        var roomAnimation: MaskAnimation?
        if searchBox.state != .joined {
            roomAnimation = searchBox.roomItem?.maskAnimation
        }
        // 申请发言
        let isSelf = searchBox.participant?.user == meeting.account
        let showMicHandsUp = searchBox.participant?.isMicHandsUp == true && (hasCohostAuthority || isSelf)
        // 申请开摄像头
        let showCameraHandsUp = searchBox.participant?.isCameraHandsUp == true && (hasCohostAuthority || isSelf)
        // 申请本地录制
        let showLocalRecordHandsUp = searchBox.participant?.isLocalRecordHandsUp == true && (hasCohostAuthority || isSelf)
        // 头像红点
        let showRedDot: Bool = showMicHandsUp || showCameraHandsUp || showLocalRecordHandsUp
        // 昵称
        var displayName: String = ""
        if let userInfo = searchBox.userInfo {
            displayName = userInfo.name
            if searchBox.lobbyParticipant != nil, let roomInfo = userInfo.room {
                displayName = roomInfo.primaryName
            }
        } else if let userItem = searchBox.userItem {
            displayName = userItem.name
        } else if let roomItem = searchBox.roomItem {
            displayName = roomItem.title
        }
        // 原始昵称（用于快捷电话邀请）
        var originalName: String = ""
        if let userInfo = searchBox.userInfo {
            originalName = userInfo.originalName
            if searchBox.lobbyParticipant != nil, let roomInfo = userInfo.room {
                originalName = roomInfo.fullName
            }
        } else if let userItem = searchBox.userItem {
            originalName = userItem.name
        } else if let roomItem = searchBox.roomItem {
            originalName = roomItem.title
        }
        // 小尾巴
        var nameTail: String?
        if searchBox.state == .joined, let participant = searchBox.participant {
            if participant.user == meeting.account {
                nameTail = " (\(I18n.View_M_Me))"
            } else if participant.isLarkGuest {
                if meeting.isInterviewMeeting {
                    nameTail = I18n.View_G_CandidateBracket
                } else {
                    nameTail = I18n.View_M_GuestParentheses
                }
            }
        }
        // 勿扰
        var showDisturbedIcon: Bool = false
        if searchBox.state != .joined {
            /// isFocusStatusFeatureEnabled always true
            showDisturbedIcon = false
        }
        // 个人状态
        var customStatuses: [User.CustomStatus] = []
        if searchBox.state != .joined {
            customStatuses = searchBox.userItem?.customStatuses ?? []
        }
        // pstn标识
        var showPstnIcon: Bool = false
        if let p = searchBox.participant, p.type == .pstnUser, let pstn = p.pstnInfo, ConveniencePSTN.isConvenience(pstn) {
            // 快捷电话邀请
            showPstnIcon = true
        } else if let p = searchBox.participant, p.type == .larkUser, p.settings.audioMode == .pstn {
            // callme用户
            showPstnIcon = true
        }
        // 设备标识
        let deviceImgKey = constructDeviceImg(searchBox: searchBox, duplicatedParticipantIds: duplicatedParticipantIds)
        // 共享标识
        let showShareIcon = constructShowShareIcon(inMeetingInfo: inMeetingInfo, participant: searchBox.participant)
        // 主持人标签
        let roleConfig = searchBox.participant?.roleConfig(hostEnabled: hostEnabled, isInterview: meeting.isInterviewMeeting)
        // 传译员标签
        var interpretKey: String?
        if let interpreterSetting = searchBox.participant?.settings.interpreterSetting,
           interpreterSetting.isUserConfirm,
           !interpreterSetting.interpretingLanguage.isMain {
            interpretKey = interpreterSetting.interpretingLanguage.despI18NKey
        }
        // 用户标签(请假 or 外部)
        var userFlag: UserFlagType = .none
        let hasOnLeave = searchBox.state != .joined && !meeting.setting.isNewStatusEnabled // 会中不展示请假标签, 如果使用主端的个人状态组件，也无需额外显示请假标签
        var isExternal = false
        var relationTagWhenRing: CollaborationRelationTag?
        if let participant = searchBox.participant {
            isExternal = participant.isExternal(localParticipant: meeting.myself)
        } else if let userItem = searchBox.userItem {
            isExternal = userItem.isExternal
            relationTagWhenRing = userItem.relationTagWhenRing
        }
        var isOnLeave = false
        if let userItem = searchBox.userItem {
            isOnLeave = userItem.workStatus == .leave
        }
        if isExternal {
            userFlag = .external
            // 命中 fg 且搜索结果有 relationTagWhenRing 才展示关联标签
            if meeting.setting.isRelationTagEnabled,
               let userFlagType = UserFlagType.fromCollaborationTag(relationTagWhenRing) {
                userFlag = userFlagType
            }
        } else if isOnLeave && hasOnLeave {
            userFlag = .onLeave
        }
        let showLeaveIcon = searchBox.participant?.settings.conditionEmojiInfo?.isStepUp ?? false
        // 焦点视频
        let showFocus = constructShowFocus(inMeetingInfo: inMeetingInfo, participant: searchBox.participant)
        // 副标题
        var subtitle: String?
        if searchBox.state != .joined {
            if let userItem = searchBox.userItem {
                subtitle = userItem.description
            } else if let roomItem = searchBox.roomItem {
                subtitle = roomItem.subtitle
            }
        }
        // 按钮样式
        let buttonStyle = constructButtonStyle(from: from, searchBox: searchBox, enableInvitePSTN: enableInvitePSTN)

        let model = SearchParticipantCellModel(selectionStyle: selectionStyle,
                                               avatarInfo: avatarInfo,
                                               roomAnimation: roomAnimation,
                                               showRedDot: showRedDot,
                                               displayName: displayName,
                                               originalName: originalName,
                                               nameTail: nameTail,
                                               showDisturbedIcon: showDisturbedIcon,
                                               customStatuses: customStatuses,
                                               showPstnIcon: showPstnIcon,
                                               deviceImg: deviceImgKey,
                                               showShareIcon: showShareIcon,
                                               showLeaveIcon: showLeaveIcon,
                                               roleConfig: roleConfig,
                                               interpretKey: interpretKey,
                                               userFlag: userFlag,
                                               showFocus: showFocus,
                                               showMicHandsUp: showMicHandsUp,
                                               showCameraHandsUp: showCameraHandsUp,
                                               showLocalRecordHandsUp: showLocalRecordHandsUp,
                                               subtitle: subtitle,
                                               buttonStyle: buttonStyle,
                                               searchBox: searchBox,
                                               enableInvitePSTN: enableInvitePSTN,
                                               service: meeting.service)
        return model
    }
    // enable-lint: long function
}

// MARK: - public
extension SearchParticipantCellModel {
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

// MARK: - private
extension SearchParticipantCellModel {

    /// 设备标识
    private static func constructDeviceImg(searchBox: ParticipantSearchBox, duplicatedParticipantIds: Set<String>) -> ParticipantImgKey {
        // 设备标识
         var deviceImg: ParticipantImgKey = .empty
        if let p = searchBox.participant, duplicatedParticipantIds.contains(p.user.id) {
             switch p.deviceType {
             case .mobile:
                 deviceImg = .mobileDevice
             case .web:
                 deviceImg = .webDevice
             default: break
             }
         }
        return deviceImg
    }

    /// 共享标识
    private static func constructShowShareIcon(inMeetingInfo: VideoChatInMeetingInfo?, participant: Participant?) -> Bool {
        return inMeetingInfo?.checkIsUserSharingContent(with: participant?.user) ?? false
    }

    /// 焦点视频
    private static func constructShowFocus(inMeetingInfo: VideoChatInMeetingInfo?, participant: Participant?) -> Bool {
        var showFocus = false
        if let participant = participant {
            showFocus = inMeetingInfo?.focusingUser == participant.user
        }
        return showFocus
    }

    /// 是否支持快捷电话邀请
    private static func constructEnableInvitePSTN(searchBox: ParticipantSearchBox, localParticipant: Participant?,
                                                  featureManager: MeetingSettingManager, meetingTenantId: String?, meetingSubType: MeetingSubType) -> Bool {
        var enableInvitePSTN: Bool = false
        if let participant = searchBox.participant {
            enableInvitePSTN = ConveniencePSTN.enableInviteParticipant(participant, local: localParticipant,
                                                                       featureManager: featureManager, meetingTenantId: meetingTenantId, meetingSubType: meetingSubType)
        } else if let byteviewUser = searchBox.userItem?.byteviewUser, let crossTenant = searchBox.userItem?.crossTenant {
            enableInvitePSTN = ConveniencePSTN.enableInviteParticipant(byteviewUser, local: localParticipant,
                                                                       crossTenant: crossTenant,
                                                                       featureManager: featureManager, meetingTenantId: meetingTenantId)
        }
        return enableInvitePSTN
    }

    /// 高亮效果
    private static func constructSelectionStyle(from: FromType, searchBox: ParticipantSearchBox, hasHostCohostAuthority: Bool,
                                                currentUser: ByteviewUser, magicShareDocument: MagicShareDocument?, enableInvitePSTN: Bool) -> UITableViewCell.SelectionStyle {
        var canManipulate: Bool = false
        if from == .interpret || from == .commonSearch {
            canManipulate = true
        } else {
            switch searchBox.state {
            case .joined:
                let isSelf = currentUser == searchBox.participant?.user
                let enablePassOnSharing = magicShareDocument?.user == currentUser // 是否支持转移共享
                canManipulate = isSelf || hasHostCohostAuthority || enablePassOnSharing || enableInvitePSTN
            case .inviting:
                let selfIsInviter = searchBox.userItem?.participant?.inviter == currentUser
                canManipulate = hasHostCohostAuthority || selfIsInviter
            case .waiting:
                canManipulate = hasHostCohostAuthority
            default: break
            }
        }
        let selectionStyle: UITableViewCell.SelectionStyle = canManipulate ? .default : .none
        return selectionStyle
    }

    /// 按钮样式
    private static func constructButtonStyle(from: FromType, searchBox: ParticipantSearchBox, enableInvitePSTN: Bool) -> ParticipantButton.Style {
        var buttonStyle: ParticipantButton.Style = .none
        if from == .participant {
            if searchBox.state == .inviting {
                buttonStyle = .calling
            } else if searchBox.state == .joined {
                buttonStyle = .joined
            } else if searchBox.state == .waiting {
                buttonStyle = .waiting
            } else {
                if enableInvitePSTN {   // 之前会判断 userItem.isCollaborationTypeLimitedBlocked，限制用户音视频沟通权限 需求去掉
                    buttonStyle = .moreCall
                } else {
                    buttonStyle = .call
                }
            }
        }
        return buttonStyle
    }
}

// MARK: - ParticipantCellModelUpdate
extension SearchParticipantCellModel: ParticipantCellModelUpdate {

    func updateRole(with meeting: InMeetMeeting) {
        roleConfig = searchBox.participant?.roleConfig(hostEnabled: meeting.setting.isHostEnabled, isInterview: meeting.isInterviewMeeting)
    }

    func updateShowShareIcon(with inMeetingInfo: VideoChatInMeetingInfo?) {
        showShareIcon = SearchParticipantCellModel.constructShowShareIcon(inMeetingInfo: inMeetingInfo, participant: searchBox.participant)
    }

    func updateShowFocus(with inMeetingInfo: VideoChatInMeetingInfo?) {
        showFocus = SearchParticipantCellModel.constructShowFocus(inMeetingInfo: inMeetingInfo, participant: searchBox.participant)
    }

    func updateDeviceImg(with duplicatedParticipantIds: Set<String>) {
        deviceImgKey = SearchParticipantCellModel.constructDeviceImg(searchBox: searchBox, duplicatedParticipantIds: duplicatedParticipantIds)
    }
}
