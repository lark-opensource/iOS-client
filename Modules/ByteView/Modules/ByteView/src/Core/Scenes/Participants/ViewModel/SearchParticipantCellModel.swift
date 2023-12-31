//
//  SearchParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class SearchParticipantCellModel: BaseParticipantCellModel {

    /// 高亮效果
    var selectionStyle: UITableViewCell.SelectionStyle
    /// room会中动画
    let roomAnimation: MaskAnimation?
    /// 原始昵称（用于快捷电话邀请）
    let originalName: String
    /// 勿扰
    let showDisturbedIcon: Bool
    /// 个人状态
    let customStatuses: [User.CustomStatus]
    /// pstn标识(CallMe/快捷电话邀请)
    var showPstnIcon: Bool
    /// 设备标识(手机/web)
    var deviceImgKey: ParticipantImgKey
    /// 共享标识
    var showShareIcon: Bool
    /// 离开状态
    var showLeaveIcon: Bool
    /// 主持人/联席主持人标签
    var roleConfig: ParticipantRoleConfig?
    /// 传译标签Key，用于拉取传译标签
    let interpretKey: String?
    /// 传译标签
    var interpret: String?
    /// 用户标签(请假 or 外部)
    private(set) var userFlag: UserFlagType
    /// 焦点视频
    var showFocus: Bool
    /// 申请发言
    let showMicHandsUp: Bool
    /// 申请开启摄像头
    let showCameraHandsUp: Bool
    /// 申请开启本地录制
    let showLocalRecordHandsUp: Bool
    /// 子标题
    let subtitle: String?
    /// 按钮样式
    var buttonStyle: ParticipantButton.Style
    /// 搜索结果
    let searchBox: ParticipantSearchBox
    /// 是否支持快捷电话邀请
    var enableInvitePSTN: Bool

    init(selectionStyle: UITableViewCell.SelectionStyle,
         avatarInfo: AvatarInfo,
         roomAnimation: MaskAnimation?,
         showRedDot: Bool,
         displayName: String,
         originalName: String,
         nameTail: String?,
         showDisturbedIcon: Bool,
         customStatuses: [User.CustomStatus],
         showPstnIcon: Bool,
         deviceImg: ParticipantImgKey,
         showShareIcon: Bool,
         showLeaveIcon: Bool,
         roleConfig: ParticipantRoleConfig?,
         interpretKey: String?,
         userFlag: UserFlagType,
         showFocus: Bool,
         showMicHandsUp: Bool,
         showCameraHandsUp: Bool,
         showLocalRecordHandsUp: Bool,
         subtitle: String?,
         buttonStyle: ParticipantButton.Style,
         searchBox: ParticipantSearchBox,
         enableInvitePSTN: Bool,
         service: MeetingBasicService
    ) {
        self.selectionStyle = selectionStyle
        self.roomAnimation = roomAnimation
        self.originalName = originalName
        self.showDisturbedIcon = showDisturbedIcon
        self.customStatuses = customStatuses
        self.showPstnIcon = showPstnIcon
        self.deviceImgKey = deviceImg
        self.showShareIcon = showShareIcon
        self.showLeaveIcon = showLeaveIcon
        self.roleConfig = roleConfig
        self.interpretKey = interpretKey
        self.userFlag = userFlag
        self.showFocus = showFocus
        self.showMicHandsUp = showMicHandsUp
        self.showCameraHandsUp = showCameraHandsUp
        self.showLocalRecordHandsUp = showLocalRecordHandsUp
        self.subtitle = subtitle
        self.buttonStyle = buttonStyle
        self.searchBox = searchBox
        self.enableInvitePSTN = enableInvitePSTN
        super.init(avatarInfo: avatarInfo, showRedDot: showRedDot, displayName: displayName, nameTail: nameTail, pID: searchBox.id, service: service)
    }

    private var byteViewUser: ByteviewUser? {
        var user: ByteviewUser?
        if let searchUserBox = searchBox as? ParticipantSearchUserBox {
            user = searchUserBox.user.byteviewUser
        } else if let searchRoomBox = searchBox as? ParticipantSearchRoomBox {
            user = searchRoomBox.room.byteviewUser
        }
        return user
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { byteViewUser?.relationTagUser }

    override func relationTagUserID() -> String? { byteViewUser?.id }
}
