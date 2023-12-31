//
//  LobbyParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

// MARK: - Construction
extension LobbyParticipantCellModel {

    static func create(with lobbyParticipant: LobbyParticipant,
                       userInfo: ParticipantUserInfo?,
                       showRoomInfo: Bool,
                       meeting: InMeetMeeting) -> LobbyParticipantCellModel {
        // 头像
        let avatarInfo: AvatarInfo? = userInfo?.avatarInfo
        // 昵称
        var displayName: String? = userInfo?.name
        if showRoomInfo, let roomInfo = userInfo?.room {
            displayName = roomInfo.primaryName
        }
        // 昵称小尾巴
        var nameTail: String?
        if lobbyParticipant.isLarkGuest {
            if meeting.isInterviewMeeting {
                nameTail = I18n.View_G_CandidateBracket
            } else {
                nameTail = I18n.View_M_GuestParentheses
            }
        }
        // 是否是快捷电话邀请
        var isConveniencePSTN: Bool = false
        if lobbyParticipant.user.type == .pstnUser, ConveniencePSTN.isConvenience(bindId: lobbyParticipant.bindId, bindType: lobbyParticipant.bindType) {
            isConveniencePSTN = true
        }
        // 设备标识
        var deviceImg: ParticipantImgKey = .empty
        if isConveniencePSTN {
            deviceImg = .conveniencePstn
        }
        // 用户标签(外部)
        let isExternal = lobbyParticipant.isExternal(localParticipant: meeting.myself)
        let userFlag: UserFlagType = isExternal ? .external : .none
        // 移出等候室
        let isWaiting = lobbyParticipant.isStatusWait
        let isJoining = lobbyParticipant.isInApproval
        let removeButtonStyle: ParticipantButton.Style = (isWaiting && !isJoining) ? .remove : .none
        /// 允许入会/正在加入
        var admitButtonStyle: ParticipantButton.Style = .admit
        if isWaiting && isJoining {
            admitButtonStyle = .joining
        }

        let model = LobbyParticipantCellModel(avatarInfo: avatarInfo,
                                              displayName: displayName,
                                              nameTail: nameTail,
                                              deviceImg: deviceImg,
                                              userFlag: userFlag,
                                              room: "",
                                              removeButtonStyle: removeButtonStyle,
                                              admitButtonStyle: admitButtonStyle,
                                              lobbyParticipant: lobbyParticipant,
                                              isConveniencePSTN: isConveniencePSTN,
                                              showRoomInfo: showRoomInfo,
                                              service: meeting.service)
        return model
    }
}

// MARK: - public
extension LobbyParticipantCellModel {
    /// 拉取昵称、头像等详细信息
    func getDetailInfo(_ callback: @escaping (() -> Void)) {
        if avatarInfo != nil, displayName != nil {
            callback()
            return
        }
        httpClient.participantService.participantInfo(pid: lobbyParticipant, meetingId: lobbyParticipant.meetingId) { userInfo in
            // 该回调在主线程
            guard userInfo.pid == self.lobbyParticipant.participantId else { return } // 避免重用
            // 头像
            let avatarInfo: AvatarInfo = userInfo.avatarInfo
            self.avatarInfo = avatarInfo
            // 昵称
            var displayName: String = userInfo.name
            let showRoomInfo = userInfo.room != nil ? self.showRoomInfo : false
            if showRoomInfo, let roomInfo = userInfo.room {
                displayName = roomInfo.primaryName
            }
            self.displayName = displayName
            callback()
        }
    }
}
