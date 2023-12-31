//
//  ParticipantTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

final class ParticipantTracks {

    private static let userListPage = TrackEventName.vc_meeting_page_userlist

    /// 推荐列表点击用户calling
    static func trackInviteFromSuggestList(userId: String) {
        VCTracker.post(name: .vc_meeting_page_suggest_list,
                       params: [.action_name: "calling",
                                .extend_value: ["uuid": EncryptoIdKit.encryptoId(userId)]])
    }

    /// 搜索列表选择用户calling
    static func trackInviteFromSearchList(userId: String) {
        VCTracker.post(name: .vc_meeting_page_search_list,
                       params: [.action_name: "calling",
                                .extend_value: ["uuid": EncryptoIdKit.encryptoId(userId)]])
    }

    /// 用户关闭摄像头
    static func trackEnableCamera(enabled: Bool, user: ByteviewUser, isSearch: Bool) {
        VCTracker.post(name: userListPage,
                       params: [.from_source: isSearch ? "search_userlist" : "userlist",
                                .action_name: "camera",
                                .extend_value: ["action_enabled": enabled ? 1 : 0,
                                                "attendee_uuid": EncryptoIdKit.encryptoId(user.id),
                                                "attendee_device_id": user.deviceId]])
    }

    /// 静音用户
    static func trackEnableMic(enabled: Bool, user: ByteviewUser, isSearch: Bool) {
        VCTracker.post(name: userListPage,
                       params: [.from_source: isSearch ? "search_userlist" : "userlist",
                                .action_name: "mic",
                                .extend_value: ["action_enabled": enabled ? 1 : 0,
                                                "attendee_uuid": EncryptoIdKit.encryptoId(user.id),
                                                "attendee_device_id": user.deviceId]])
    }

    /// 全员禁用麦克风
    static func trackEnableAllMic(enabled: Bool, isOpenBreakoutRoom: Bool, isInBreakoutRoom: Bool) {
        let breakoutRoomStart = BreakoutRoomTracks.isStart(isOpenBreakoutRoom)
        var params: TrackParams = [.action_name: "all_mute",
                                   .extend_value: ["action_enabled": enabled ? 1 : 0],
                                   BreakoutRoomTracks.Start.key: breakoutRoomStart]
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(isInBreakoutRoom)
        VCTracker.post(name: userListPage, params: params)
    }

    /// 参会者列表点击calling
    static func trackCalling(participant: Participant) {
        var params: TrackParams = [.action_name: "calling"]
        params[.extend_value] = ["attendee_uuid": EncryptoIdKit.encryptoId(participant.user.id),
                                 "attendee_device_id": participant.deviceId]
        VCTracker.post(name: userListPage, params: params)
    }

    /// 焦点视频
    static func trackFocusVideo(withdraw: Bool, location: String) {
        let params: TrackParams = [.click: withdraw ? "release_focus" : "set_focus",
                                   .location: location]
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    /// 参会者（搜索）列表点击cancel
    static func trackCancelCalling(participant: Participant, isSearch: Bool) {
        var params: TrackParams = [.from_source: isSearch ? "search_userlist" : "userlist",
                                   .action_name: "cancel"]
        params[.extend_value] = ["attendee_uuid": EncryptoIdKit.encryptoId(participant.user.id),
                                 "attendee_device_id": participant.deviceId]
        VCTracker.post(name: userListPage, params: params)
    }

    static func trackCopyLink() {
        VCTracker.post(name: userListPage, params: [.action_name: "copy_meeting_link"])
    }

    static func trackCopyMeetingInfo() {
        VCTracker.post(name: userListPage, params: [.action_name: "copy_join_info"])
    }

    static func trackShare() {
        VCTracker.post(name: userListPage, params: [.action_name: "share"])
    }

    static func trackStopShare(isSearch: Bool, userId: String, deviceId: String) {
        VCTracker.post(name: userListPage,
                       params: [.from_source: isSearch ? "search_userlist" : "userlist",
                                .action_name: "stop_sharing",
                                .extend_value: ["attendee_uuid": EncryptoIdKit.encryptoId(userId),
                                                "attendee_device_id": deviceId]])
    }

    /// 踢人
    static func trackKickOutParticipant(_ participant: Participant, isSearch: Bool) {
        var params: TrackParams = [.from_source: isSearch ? "search_userlist" : "userlist",
                                   .action_name: "remove_user"]
        params[.extend_value] = ["attendee_uuid": EncryptoIdKit.encryptoId(participant.user.id),
                                 "attendee_device_id": participant.deviceId]
        VCTracker.post(name: userListPage, params: params)
    }

    /// 转移主持人
    static func trackTransferHost(to participant: Participant, isSearch: Bool) {
        var params: TrackParams = [.from_source: isSearch ? "search_userlist" : "userlist",
                                   .action_name: "assign_host"]
        params[.extend_value] = ["attendee_uuid": EncryptoIdKit.encryptoId(participant.user.id),
                                 "attendee_device_id": participant.deviceId]
        VCTracker.post(name: userListPage, params: params)
    }

    static func trackPopup(_ source: String, params extra: [String: Any] = [:]) {
        var params: TrackParams = [.action_name: "display", .from_source: source]
        params.updateParams(extra)
        VCTracker.post(name: .vc_meeting_popup, params: params)
    }

    static func trackJumpToProfile(userId: String, deviceId: String?) {
        var params: TrackParams = [.action_name: "user_profile",
                                   .from_source: "user_list"]
        var extends: [String: Any] = ["attendee_uuid": EncryptoIdKit.encryptoId(userId)]
        if let deviceId = deviceId, !deviceId.isEmpty {
            extends["attendee_device_id"] = deviceId
        }
        params[.extend_value] = extends
        VCTracker.post(name: userListPage, params: params)
    }

    static func trackCoreManipulation(isSelf: Bool, description: String, participant: Participant) {
        let message = "isSelf: \(isSelf); description: \(description); uid: \(participant.user.id); did: \(participant.deviceId)"
        Logger.participant.info("Manipulate participant: \(message)")
    }

    static func trackCoreManipulation(isSelf: Bool, description: String, uid: String, did: String) {
        let message = "isSelf: \(isSelf); description: \(description); uid: \(uid); did: \(did)"
        Logger.participant.info("Manipulate participant: \(message)")
    }

    static func trackInvitePSTN(isFromGridView: Bool, suggestionCount: Int?) {
        let defaultCount: Int = -99
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "invite_join_by_phone",
                                .location: isFromGridView ? "user_icon" : "userlist",
                                .suggestionNum: suggestionCount ?? defaultCount]) // 和埋点同学约定，iOS在参会人列表外，上报建议人员个数的场景，统一传: -99
    }

    static func trackCancelInvite(isConveniencePSTN: Bool, suggestionCount: Int) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "cancel_call",
                                "type_of_call": isConveniencePSTN ? "phone_call" : "audio_video_call",
                                .suggestionNum: suggestionCount])
    }

    static func trackConvertToInvitePSTN(suggestionCount: Int) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "convert_to_phone_call",
                                .suggestionNum: suggestionCount])
    }

    static func trackFullScreen(click: String) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: click])
    }

    static func trackLocalRecordClick(isFromGridView: Bool, isStop: Bool = false, isAgree: Bool = false, isRefuse: Bool = false) {
        guard isStop || isAgree || isRefuse else { return }
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: isStop ? "stop_local_record" : isAgree ? "agree_local_record_request" : "refuse_local_record_request",
                                .location: isFromGridView ? "user_icon" : "userlist"])
    }
}

extension ParticipantTracks {
    enum ParticipantAction {
        /// 参会人的点点点“...”按钮
        case participantMore
        /// 点击参会人的头像或者名字
        case userInformation
        /// 开启视频
        case openVideo
        /// 停止视频
        case stopVideo
        /// 打开关闭麦克风
        case participantMic(isOn: Bool)
        /// 修改名称
        case rename
        /// 设置主持人
        case setHost
        /// 收回主持人
        case cancelHost
        /// 设置联席主持人
        case setCoHost
        /// 取消联席主持人
        case cancelCoHost
        /// 移出会议
        case removeParticipant

        var click: String {
            switch self {
            case .participantMore: return "participant_more"
            case .userInformation: return "user_information"
            case .openVideo: return "open_video"
            case .stopVideo: return "stop_video"
            case .participantMic: return "participant_mic"
            case .rename: return "rename"
            case .setHost: return "set_host"
            case .cancelHost: return "cancel_host"
            case .setCoHost: return "set_co_host"
            case .cancelCoHost: return "cancel_co_host"
            case .removeParticipant: return "remove_participant"
            }
        }

        var target: String {
            switch self {
            case .userInformation:
                return "profile_main_view"
            case .rename:
                return "vc_meeting_popup_view"
            default:
                return "none"
            }
        }

        var option: String? {
            switch self {
            case let .participantMic(isOn):
                return isOn ? "open" : "close"
            default:
                return nil
            }
        }
    }

    static func trackParticipantAction(_ action: ParticipantAction, isFromGridView: Bool, isSharing: Bool, isRooms: Bool? = nil) {
        var params: TrackParams = [.click: action.click,
                                   .target: action.target,
                                   .location: isFromGridView ? "user_icon" : "userlist",
                                   "is_sharing": isSharing]
        if let isRooms = isRooms {
            params["parti_type"] = isRooms ? "rooms" : "normal"
        }
        if let option = action.option {
            params[.option] = option
        }
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: params)
    }
}
