//
//  ParticipantAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/8.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewUI
import UniverseDesignColor

enum ParticipantActionType {

    // ------ only myself -----

    /// 撤销申请（开麦/开摄/开麦摄）
    case withdrawUnmute
    /// 隐藏自己
    case hideSelf


    // ------ only other -----

    /// 允许本地录制
    case allowLocalRecord
    /// 拒绝本地录制
    case declineLocalRecord
    /// 拒绝申请（开麦/开摄/开麦摄）
    case declineUnMute
    /// 转移主持人
    case makeHost
    /// 转移联席
    case makeCohost
    /// 切换嘉宾/观众身份
    case changeRole
    /// 转移共享
    case passOnSharing
    /// 拨号盘
    case sipDialPad
    /// 停止本地录制
    case stopLocalRecord
    /// 停止共享
    case stopShare
    /// 移至等候室
    case moveToLobby
    /// 移出会议
    case remove
    /// 取消邀请
    case cancelInvite
    /// 等候室准入
    case lobbyAdmit
    /// 等候室移出
    case lobbyRemove


    // -------- both -------

    /// 全屏
    case fullScreen
    /// 麦克风
    case microphone
    /// 放下举手表情
    case putDownHandsUpEmoji
    /// 摄像头
    case camera
    /// 隐藏无视频
    case hideNoVideo
    /// 焦点视频
    case focusVideo
    /// 调整顺序
    case adjustPosition
    /// 改名
    case rename
    /// 快捷电话邀请
    case phoneCall

}

extension ParticipantActionRegistry {

    static func defaultOrdered() -> [ParticipantActionSection] {
        let builder = ParticipantActionBuilder()
        /// 按区/行顺序添加 https://bytedance.feishu.cn/docx/RokAdq9ZhoDpxdxCDfJcXaGCnRh
        builder
            // 音视频类
            .section()
            .row(.fullScreen, action: ParticipantFullScreenAction.self)
            .row(.declineUnMute, action: ParticipantDeclineUnMuteAction.self)
            .row(.putDownHandsUpEmoji, action: ParticipantPutDownEmojiAction.self)
            .row(.withdrawUnmute, action: ParticipantWithdrawUnmuteAction.self)
            .row(.microphone, action: ParticipantMicrophoneAction.self)
            .row(.camera, action: ParticipantCameraAction.self)
            .row(.hideSelf, action: PaticipantHideSelfAction.self)
            .row(.hideNoVideo, action: ParticipantHideNoVideoAction.self)
            .row(.focusVideo, action: ParticipantFocusVideoAction.self)
            .row(.adjustPosition, action: ParticipantAdjustPositionAction.self)
            // 本地录制类
            .section()
            .row(.allowLocalRecord, action: ParticipantAllowLocalRecordAction.self)
            .row(.declineLocalRecord, action: ParticipantDeclineLocalRecordAction.self)
            .row(.stopLocalRecord, action: ParticipantStopLocalRecordAction.self)
            // 会控角色类
            .section()
            .row(.makeHost, action: ParticipantMakeHostAction.self)
            .row(.makeCohost, action: ParticipantMakeCohostAction.self)
            .row(.changeRole, action: ParticipantChangeRoleAction.self)
            // 功能类
            .section()
            .row(.rename, action: ParticipantRenameAction.self)
            .row(.phoneCall, action: ParticipantPhoneCallAction.self)
            .row(.sipDialPad, action: ParticipantSipDialPadAction.self)
            .row(.passOnSharing, action: ParticipantPassOnSharingAction.self)
            .row(.stopShare, action: ParticipantStopShareAction.self)
            // 离开会议类
            .section()
            .row(.moveToLobby, action: ParticipantMoveToLobbyAction.self)
            .row(.remove, action: ParticipantRemoveAction.self)
        return builder.build()
    }

    static func inviteeOrdered() -> [ParticipantActionSection] {
        let builder = ParticipantActionBuilder()
        builder
            .section()
            .row(.cancelInvite, action: ParticipantCancelInviteAction.self)
        return builder.build()
    }

    static func lobbyOrdered() -> [ParticipantActionSection] {
        let builder = ParticipantActionBuilder()
        builder
            .section()
            .row(.lobbyAdmit, action: ParticipantLobbyAdmitAction.self)
            .row(.lobbyRemove, action: ParticipantLobbyRemoveAction.self)
        return builder.build()
    }
}

enum ParticipantActionSource {
    /// 宫格流
    case grid
    /// 单流放大
    case single
    /// 参会人列表`全部`tab
    case allList
    /// 参会人列表`观众`tab``
    case attendeeList
    /// 参会人搜索列表
    case searchList
    /// calling用户
    case invitee
    /// lobby
    case lobby

    var fromGrid: Bool {
        switch self {
        case .grid, .single: return true
        case .allList, .attendeeList, .searchList, .invitee, .lobby: return false
        }
    }

    var isSearch: Bool {
        switch self {
        case .searchList: return true
        case .grid, .single, .allList, .attendeeList, .invitee, .lobby: return false
        }
    }

    var track: String {
        switch self {
        case .grid, .single: return "user_icon"
        case .allList, .attendeeList, .searchList: return "userlist"
        case .invitee, .lobby: return ""
        }
    }
}
