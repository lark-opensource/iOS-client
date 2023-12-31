//
//  LiveSettingTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

final class LiveSettingTracks {

    private static let liveSetting = TrackEventName.vc_live_setting_page

    static func trackSwitchLiveBrand(isLiving: Bool, liveId: Int64?, newLiveBrand: LiveBrand) {
        let action = newLiveBrand == .larkLive ? "switch_live_brand_to_lark_live" : "switch_live_brand_to_byte_live"
        let params: TrackParams = ["is_live": isLiving ? 1 : 0,
                                   .action_name: action,
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackCopyLink(isLiving: Bool, liveId: Int64?) {
        let params: TrackParams = ["is_live": isLiving ? 1 : 0,
                                   .action_name: "copy_livestreaminglink",
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackSelectPrivilege(_ privilege: LivePrivilege, isLiving: Bool, liveId: Int64?) {
        let params: TrackParams = ["is_live": isLiving ? 1 : 0,
                                   .action_name: convertPrivilege(privilege),
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackSelectLayout(_ layout: LiveLayout, isLiving: Bool, liveId: Int64?) {
        let params: TrackParams = ["is_live": isLiving ? 1 : 0,
                                   .action_name: convertLayout(layout),
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackLiveChatEnable(_ enable: Bool, isLiving: Bool, liveId: Int64?) {
        let action = enable ? "enable_live_chat_for_viewers" : "disable_live_chat_for_viewers"
        let params: TrackParams = ["is_live": isLiving ? 1 : 0,
                                   .action_name: action,
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackPlaybackEnable(_ enable: Bool, isLiving: Bool, liveId: Int64?) {
        let action = enable ? "enable_save_playback_for_viewers" : "disable_save_playback_for_viewers"
        let params: TrackParams = ["is_live": isLiving ? 1 : 0,
                                   .action_name: action,
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackStartLiveStreaming(isLiving: Bool, liveId: Int64?, isLiveChatEnabled: Bool?,
                                        selectedLayout: LiveLayout?,
                                        selectedPrivilege: LivePrivilege?,
                                        brand: LiveBrand) {
        let params: TrackParams = [.action_name: "begin_live",
                                   "in_live": isLiving ? 1 : 0,
                                   "live_range": convertPrivilege(selectedPrivilege),
                                   "enable_live_chat_for_viewers": isLiveChatEnabled == true ? 1 : 0,
                                   "livestream_layout": convertLayout(selectedLayout),
                                   "brand": convertBrand(brand),
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackStopLivestreaming(liveId: Int64?) {
        let params: TrackParams = [.action_name: "end_live",
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: liveSetting, params: params)
    }

    static func trackStopLiveAlert(isConfirm: Bool) {
        VCTracker.post(name: .vc_end_live_popup,
                       params: [.action_name: isConfirm ? "confirm" : "cancel"])
    }

    private static func convertPrivilege(_ privilege: LivePrivilege?) -> String {
        guard let privilege = privilege else {
            return "unknown"
        }

        switch privilege {
        case .anonymous:
            return "all_user"
        case .employee:
            return "inside_user"
        case .chat:
            return "chat_user"
        case .custom:
            return "custom_user"
        case .other:
            return "other_user"
        default:
            return "unknown"
        }
    }

    private static func convertLayout(_ layout: LiveLayout?) -> String {
        guard let layout = layout else {
            return "unknown"
        }

        switch layout {
        case .list:
            return "sidebar"
        case .gallery:
            return "gallery"
        case .simple:
            return "full_screen"
        case .speaker:
            return "speaker"
        default:
            return "unknown"
        }
    }

    private static func convertBrand(_ brand: LiveBrand) -> String {
        switch brand {
        case .larkLive:
            return "lark_live"
        case .byteLive:
            return "byte_live"
        default:
            return "unknow"
        }
    }
}

final class LiveSettingTracksV2 {

    private static let clickLiveSetting = TrackEventName.vc_live_meeting_setting_click

    /// 会中点击开始直播上报
    /// - Parameters:
    ///   - isLiving: 直播是否已经开启
    ///   - isLiveChatEnabled: 是否勾选允许观众互动
    ///   - selectedLayout: 选择的观众视图类型
    ///   - selectedPrivilege: 观看权限勾选的内容
    static func trackClickLiveButton(isLiving: Bool,
                                     isLiveChatEnabled: Bool?,
                                     selectedLayout: LiveLayout?,
                                     selectedPrivilege: LivePrivilege?,
                                     brand: LiveBrand,
                                     liveId: Int64?,
                                     liveSessionId: String?) {
        let target: TrackEventName = isLiving ? .vc_live_confirm_view : .vc_meeting_onthecall_view
        let params: TrackParams = [.click: isLiving ? "end_upstreaming" : "start_upstreaming",
                                   .target: target,
                                   "change_permission": convertPrivilege(selectedPrivilege),
                                   "is_enable_live_chat": isLiveChatEnabled == true,
                                   "livestream_layout": convertLayout(selectedLayout),
                                   "brand": convertBrand(brand),
                                   "live_id": liveId ?? 0,
                                   "live_status": isLiving,
                                   "live_session_id": liveSessionId ?? "null",
                                   "live_session_type": "real"]
        VCTracker.post(name: clickLiveSetting, params: params)
    }

    /// 点击“确认停止直播”弹窗的按钮时上报
    /// - Parameter isConfirm: true -> 点击“确定”；false -> 点击“取消”
    static func trackClickStopLiveConfirmAlert(isConfirm: Bool) {
        let target: TrackEventName = isConfirm ? .vc_meeting_onthecall_view : .vc_live_meeting_setting_view
        VCTracker.post(name: .vc_live_confirm_click, params: [.click: isConfirm ? "confirm" : "cancel",
                                                        .target: target,
                                                        .content: "end_meeting_live"])
    }

    /// 弹出“确认停止直播”弹窗时上报
    static func trackStopLiveConfirmAlertView() {
        VCTracker.post(name: .vc_live_confirm_view,
                       params: [.content: "end_meeting_live"])
    }

    ///在setting页出现时上报
    static func trackSettingViewStatus(liveId: Int64?, liveStatus: Bool?, liveSessionId: String? ) {
        VCTracker.post(name: .vc_live_meeting_setting_view,
                       params: ["live_id": liveId ?? 0,
                                "live_status": liveStatus ?? false ? 1 : 0,
                                "live_session_id": liveSessionId ?? "null",
                                "live_session_type": "real"])
    }

    ///直播后点击复制链接时上报（较前老的copy的埋点补充了公参）
    static func tracLivekCopyLink(liveId: Int64?, liveStatus: Bool?, liveSessionId: String? ) {
        let params: TrackParams = [.click: "is_copy_link",
                                   .target: "vc_live_meeting_setting_view",
                                   "live_session_id": liveSessionId ?? "null",
                                   "live_status": liveStatus ?? false ? 1 : 0,
                                   "live_id": liveId ?? 0,
                                   "live_session_type": "real"]
        VCTracker.post(name: clickLiveSetting, params: params)
    }

    /// 管理指定用户点击跳转picker
    static func trackLiveMemberManageClick(liveId: Int64?, liveStatus: Bool?, liveSessionId: String? ) {
        let params: TrackParams = [.click: "manage_people",
                                   .target: "picker",
                                   "live_session_id": liveSessionId ?? "null",
                                   "live_status": liveStatus ?? false ? 1 : 0,
                                   "live_id": liveId ?? 0,
                                   "live_session_type": "real"]
        VCTracker.post(name: clickLiveSetting, params: params)
    }


    private static func convertPrivilege(_ privilege: LivePrivilege?) -> String {
        guard let privilege = privilege else {
            return "unknown"
        }

        switch privilege {
        case .anonymous:
            return "anyone"
        case .employee:
            return "organizer_company"
        case .chat:
            return "chat"
        case .custom:
            return "custom"
        case .other:
            return "other"
        default:
            return "unknown"
        }
    }

    private static func convertLayout(_ layout: LiveLayout?) -> String {
        guard let layout = layout else {
            return "unknown"
        }

        switch layout {
        case .list:
            return "sidebar"
        case .gallery:
            return "gallery"
        case .simple:
            return "full_screen"
        default:
            return "unknown"
        }
    }

    private static func convertBrand(_ brand: LiveBrand) -> String {
        switch brand {
        case .larkLive:
            return "lark_live"
        case .byteLive:
            return "byte_live"
        default:
            return "unknow"
        }
    }
}
