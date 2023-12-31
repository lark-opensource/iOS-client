//
//  LobbyParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class LobbyParticipantCellModel: BaseParticipantCellModel {
    /// 设备标识(快捷电话邀请)
    let deviceImgKey: ParticipantImgKey
    /// 外部标签
    private(set) var userFlag: UserFlagType
    /// 会议室地点
    let room: String?
    /// 移除按钮
    let removeButtonStyle: ParticipantButton.Style
    /// 允许按钮/正在加入
    let admitButtonStyle: ParticipantButton.Style
    /// 等候者
    let lobbyParticipant: LobbyParticipant
    /// 是否是快捷电话邀请
    let isConveniencePSTN: Bool
    /// room详情
    let showRoomInfo: Bool

    init(avatarInfo: AvatarInfo?,
         displayName: String?,
         nameTail: String?,
         deviceImg: ParticipantImgKey,
         userFlag: UserFlagType,
         room: String?,
         removeButtonStyle: ParticipantButton.Style,
         admitButtonStyle: ParticipantButton.Style,
         lobbyParticipant: LobbyParticipant,
         isConveniencePSTN: Bool,
         showRoomInfo: Bool,
         service: MeetingBasicService
    ) {
        self.deviceImgKey = deviceImg
        self.userFlag = userFlag
        self.room = room
        self.removeButtonStyle = removeButtonStyle
        self.admitButtonStyle = admitButtonStyle
        self.lobbyParticipant = lobbyParticipant
        self.isConveniencePSTN = isConveniencePSTN
        self.showRoomInfo = showRoomInfo
        super.init(avatarInfo: avatarInfo, showRedDot: false, displayName: displayName, nameTail: nameTail, pID: lobbyParticipant.user.id, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? LobbyParticipantCellModel else { return false }
        return canEqual(self) && super.isEqual(rhs)
        && deviceImgKey == subRhs.deviceImgKey
        && userFlag == subRhs.userFlag
        && room == subRhs.room
        && removeButtonStyle == subRhs.removeButtonStyle
        && admitButtonStyle == subRhs.admitButtonStyle
        && lobbyParticipant == subRhs.lobbyParticipant
        && isConveniencePSTN == subRhs.isConveniencePSTN
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is LobbyParticipantCellModel
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { lobbyParticipant.user.relationTagUser }

    override func relationTagUserID() -> String? { lobbyParticipant.user.id }
}

extension LobbyParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        lobbyParticipant.participantId
    }
}
