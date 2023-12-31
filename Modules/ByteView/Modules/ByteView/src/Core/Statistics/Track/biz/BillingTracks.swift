//
//  BillingTracks.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/4/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class BillingTracks {
    private static let CommonPricingPopupView = TrackEventName.common_pricing_popup_view
    private static let CommonPricingPopupClick = TrackEventName.common_pricing_popup_click

    static func trackDisplayParticipantLimitTip(isSuperAdministrator: Bool) {
        VCTracker.post(name: CommonPricingPopupView, params: ["function_type": "videochat_participant_limit",
                                                              "admin_flag": isSuperAdministrator.description])
    }

    static func trackClickParticipantLimitTip(isSuperAdministrator: Bool) {
        VCTracker.post(name: CommonPricingPopupClick, params: ["function_type": "videochat_participant_limit",
                                                               .click: "go_auth",
                                                               .target: "none",
                                                               "admin_flag": isSuperAdministrator.description])
    }

    // type: "ten_minutes"/"ending"
    static func trackDisplayDurationLimitTip(type: String, isSuperAdministrator: Bool) {
        VCTracker.post(name: CommonPricingPopupView, params: ["function_type": "videochat_duration_limit",
                                                              "pop_type": type,
                                                              "admin_flag": isSuperAdministrator.description])
    }

    static func trackClickDurationLimitTip(isSuperAdministrator: Bool) {
        VCTracker.post(name: CommonPricingPopupClick, params: ["function_type": "videochat_duration_limit",
                                                               .click: "go_upgrade",
                                                               .target: "none",
                                                               "admin_flag": isSuperAdministrator.description])
    }

    static func trackDisplaySubtitleAlert() {
        VCTracker.post(name: CommonPricingPopupView, params: ["function_type": "vc_subtitle_function"])
    }

    static func trackDisplayPSTNTips() {
        VCTracker.post(name: CommonPricingPopupView, params: ["function_type": "vc_pstn_function",
                                                              "present_time": "during_meeting"])
    }

    static func trackDisplayLobbyNotice(isPreLobby: Bool) {
        VCTracker.post(name: CommonPricingPopupView, params: ["function_type": "vc_waiting_room_function",
                                                              "is_presetting_panel": isPreLobby ? "presetting" : "host_panel"])
    }
}

final class BillingTracksV2 {

    /// 进入 PSTN 邀请界面
    static func trackEnterPSTNInvite() {
        VCTracker.post(name: .vc_meeting_phone_invite_view)
    }

    /// 电话邀请呼叫
    static func trackPSTNInviteClick(hasName: Bool, isMeetingLocked: Bool) {
        VCTracker.post(name: .vc_meeting_phone_invite_click, params: [.click: "call",
                                                                      "is_meeting_locked": isMeetingLocked,
                                                                      "is_info": hasName])
    }
}
