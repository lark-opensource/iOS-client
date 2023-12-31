//
//  HostManageRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 主持人会管
/// - HOST_MANAGE = 2308
/// - Videoconference_V1_HostManageRequest
public struct HostManageRequest {
    public static let command: NetworkCommand = .rust(.hostManage)
    public static let defaultOptions: NetworkRequestOptions? = [.keepOrder]

    public init(action: HostManageAction, meetingId: String, breakoutRoomId: String? = nil) {
        self.action = action
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
    }

    public var action: HostManageAction

    public var meetingId: String

    public var breakoutRoomId: String?

    /// 目标参会者ID, 3.2后使用participant_device_id
    public var participantId: ByteviewUser?

    public var topic: String?

    public var isMuted: Bool?

    public var isLocked: Bool?

    /// 入会时是否静音
    public var isMuteOnEntry: Bool?

    /// 入会范围设置
    public var securitySetting: VideoChatSettings.SecuritySetting?

    /// 说话语言(会议维度)
    public var globalSpokenLanguage: String?

    public var allowPartiUnmute: Bool?

    public var coHostAction: CoHostAction?

    public var onlyHostCanShare: Bool?

    public var onlyHostCanReplaceShare: Bool?

    public var interpretationSetting: InterpretationSetting?

    public var isPartiChangeNameForbidden: Bool?

    public var inMeetingName: String?

    /// 仅共享者可以标注
    public var onlyPresenterCanAnnotate: Bool?

    public var focusVideoData: FocusVideoData?

    public var panelistPermission: UpdatingPanelistPermission?

    public var attendeePermission: UpdatingAttendeePermission?

    public var webinarSettings: WebinarSettings?

    /// 排序信息
    public var videoChatDisplayOrderInfo: VideoChatDisplayOrderInfo?

    /// 纪要权限
    public var notesPermission: NotesPermission?

    /// 智能会议设置
    public var intelligentMeetingSetting: IntelligentMeetingSetting?

    public enum CoHostAction: Int {
        case unknown // = 0

        /// 设置为联席主持人
        case set // = 1

        /// 取消联席主持人身份
        case unset // = 2
    }

    public struct FocusVideoData {
        public init(focusUser: ByteviewUser) {
            self.focusUser = focusUser
            self.version = 0
        }
        public var focusUser: ByteviewUser
        public var version: Int64
    }
}

public enum HostManageAction: Int {
    case unknown // = 0
    case kickOutParticipant // = 1
    case transferHost // = 2
    case muteMicrophone // = 3
    case muteCamera // = 4
    case muteAllMicrophone // = 5
    case lockMeeting // = 6
    case changeTopic // = 7

    /// 设置是否开启入会时静音
    case muteOnEntry // = 8

    /// 设置允许入会范围
    case setSecurityLevel // = 9

    /// 为所有人选择说话语言(会议维度)
    case applyGlobalSpokenLanguage // = 10
    case allowPartiUnmute // = 11

    /// 设置联席主持人
    case setCoHost // = 12

    /// 设置仅主持人可共享
    case setOnlyHostCanShare // = 13

    ///设置仅主持人可以抢共享
    case setOnlyHostCanReplaceShare // = 14

    /// 结束当前正在进行的共享
    case stopCurrentSharing // = 15

    /// 设置会议同传能力
    case setInterpretationAction // = 16

    /// 仅共享者可以标注
    case setOnlyPresenterCanAnnotate // = 17

    /// 管理讨论组
    case manageBreakoutRoom // = 18

    /// 会议广播
    case meetingBroadcast // = 19

    /// 设置改名权限
    case setForbidPartiChangeName // = 20

    /// 会中改名
    case changeInMeetingName // = 21

    /// 设为焦点视频
    case setSpotLight // = 22

    /// 设置状态表情手放下
    case setConditionEmojiHandsDown // = 23

    /// 设置全部人状态表情手放下
    case setConditionEmojiAllHandsDown // = 24

    /// 嘉宾权限更改
    case panelistPermissionChange // = 25

    /// 设定视频顺序
    case adjustVideochatOrder // = 26

    /// 移动参会人至等候室
    case moveParticipantToLobby = 27

    /// 观众权限更改
    case attendeePermissionChange = 28

    /// 纪要权限
    case notePermission = 29

    /// 智能会议
    case intelligentMeetingSetting = 30

    /// 结束分组讨论(pb.action = .manageBreakoutRoom && pb.breakoutRoomManageInfo.type = .breakoutRoomEnd)
    case breakoutRoomEnd


    /// 网络研讨会从观众设置为嘉宾
    case webinarSetFromAttendeeToParticipant = 50

    /// 网络研讨会从嘉宾设置为观众
    case webinarSetFromParticipantToAttendee // = 51

    /// 网络研讨会基本设置修改
    case webinarSettingChange // = 52

    /// 网络研讨会设置观众麦克风
    case webinarMuteAttendeeMicrophone // = 53

    /// 网络研讨会放下观众的手
    case webinarPutDownAttendeeHands // = 54

    /// 网络研讨会放下所有观众的手
    case webinarPutDownAllAttendeeHands // = 55

    /// 网络研讨会踢出观众
    case webinarKickOutAttendee // = 56

    /// 网络研讨会主持人改观众名
    case webinarChangeAttendeeInMeetingName // = 57
}

private typealias PBHostManageRequest = HostManageRequest.ProtobufType
private typealias PBBreakoutRoomManage = Videoconference_V1_BreakoutRoomManage
extension HostManageRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_HostManageRequest

    private func toManageBreakoutRoomRequest(breakoutRoomID: String) -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.breakoutRoomID = breakoutRoomID
        var info = PBBreakoutRoomInfo()
        var settings = PBBreakoutRoomInfo.BreakoutRoomInfoSettings()
        if let muteOnEntry = isMuteOnEntry {
            settings.muteOnEntry = muteOnEntry
        }
        if let onlyPresenterCanAnnotate = onlyPresenterCanAnnotate {
            settings.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
        }
        if let allowPartiUnmute = allowPartiUnmute {
            settings.participantUnmuteDeny = !allowPartiUnmute
        }
        info.settings = settings
        info.breakoutRoomID = breakoutRoomID
        var breakoutRoomManageInfo = PBBreakoutRoomManage()
        breakoutRoomManageInfo.type = .updateSettings
        breakoutRoomManageInfo.infos = [info]
        request.action = .manageBreakoutRoom
        request.breakoutRoomManageInfo = breakoutRoomManageInfo
        // 分组会议请求
        return request
    }

    func toProtobuf() throws -> Videoconference_V1_HostManageRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
            if action == .setOnlyPresenterCanAnnotate || action == .muteOnEntry || action == .allowPartiUnmute {
                return self.toManageBreakoutRoomRequest(breakoutRoomID: id)
            }
        }
        if action == .breakoutRoomEnd {
            var breakoutRoomManageInfo = PBBreakoutRoomManage()
            breakoutRoomManageInfo.type = .breakoutRoomEnd
            request.action = .manageBreakoutRoom
            request.breakoutRoomManageInfo = breakoutRoomManageInfo
            return request
        }
        request.action = .init(rawValue: action.rawValue) ?? .unknownAction
        if let id = participantId {
            request.participantID = id.id
            request.participantDeviceID = id.deviceId
            request.participantType = id.type.pbType
        }
        if let rawValue = coHostAction?.rawValue, let action = PBHostManageRequest.SetCoHostAction(rawValue: rawValue) {
            request.setCoHostAction = action
        }
        if let isMute = isMuted {
            request.isMuted = isMute
        }
        if let isLocked = isLocked {
            request.isLocked = isLocked
        }
        if let topic = topic {
            request.topic = topic
        }
        if let muteOnEntry = isMuteOnEntry {
            request.isMuteOnEntry = muteOnEntry
        }
        if let securitySetting = securitySetting {
            request.securitySetting = securitySetting.pbType
        }
        if let language = globalSpokenLanguage {
            request.globalSpokenLanguage = language
        }
        if let allowPartiUnmute = allowPartiUnmute {
            request.allowPartiUnmute = allowPartiUnmute
        }
        if let onlyHostCanShare = onlyHostCanShare {
            request.onlyHostCanShare = onlyHostCanShare
        }
        if let onlyHostCanReplaceShare = onlyHostCanReplaceShare {
            request.onlyHostCanReplaceShare = onlyHostCanReplaceShare
        }
        if let interpretationSetting = interpretationSetting {
            request.interpretationSetting = interpretationSetting.pbHostManageType
        }
        if let onlyPresenterCanAnnotate = onlyPresenterCanAnnotate {
            request.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
        }
        if let isPartiChangeNameForbidden = isPartiChangeNameForbidden {
            request.isPartiChangeNameForbidden = isPartiChangeNameForbidden
        }
        if let inMeetingName = inMeetingName {
            request.inMeetingName = inMeetingName
        }
        if let focusVideoData = focusVideoData {
            request.focusVideoData = focusVideoData.pbType
        }
        if let panelistPermission = panelistPermission {
            request.panelistPermission = panelistPermission.pbType
        }
        if let attendeePermission = attendeePermission {
            request.attendeePermission = attendeePermission.pbType
        }
        if let orderInfo = videoChatDisplayOrderInfo {
            request.videoChatDisplayOrderInfo = orderInfo.pbType
        }
        if let webinarSettings = self.webinarSettings {
            request.webinarSettings = webinarSettings.pbType
        }
        if let notesPermission = notesPermission {
            request.notesPermission = notesPermission.pbType
        }
        if let intelligentMeetingSetting = intelligentMeetingSetting {
            request.intelligentMeetingSetting = intelligentMeetingSetting.pbType
        }
        return request
    }
}

private extension HostManageRequest.FocusVideoData {
    var pbType: PBHostManageRequest.FocusVideoData {
        var focusData = PBHostManageRequest.FocusVideoData()
        focusData.version = version
        focusData.focusUser = focusUser.pbType
        return focusData
    }
}

private extension VideoChatSettings.SecuritySetting {
    var pbType: PBSecuritySetting {
        var setting = PBSecuritySetting()
        setting.securityLevel = .init(rawValue: securityLevel.rawValue) ?? .unknown
        setting.isOpenLobby = isOpenLobby
        setting.userIds = userIds
        setting.groupIds = groupIds
        setting.roomIds = roomIds
        setting.specialGroupType = specialGroupType.compactMap { .init(rawValue: $0.rawValue) }
        return setting
    }
}

private extension NotesPermission {
    var pbType: PBNotesPermission {
        var permission = PBNotesPermission()
        permission.isOwnerOrganizer = isOwnerOrganizer
        permission.createPermission = .init(rawValue: createPermission.rawValue) ?? .unknown
        permission.editPermission = .init(rawValue: editpermission.rawValue) ?? .unknown
        return permission
    }
}

extension VideoChatDisplayOrderInfo {
    var pbType: PBVideoChatDisplayOrderInfo {
        var info = PBVideoChatDisplayOrderInfo()
        info.action = .init(rawValue: action.rawValue) ?? .videoChatOrderUnknown
        info.orderList = orderList.map { $0.pbType }
        info.shareStreamInsertPosition = shareStreamInsertPosition
        info.versionID = versionID
        info.indexBegin = indexBegin
        info.hostSyncSeqID = hostSyncSeqID
        info.hasMore_p = hasMore_p
        return info
    }
}
