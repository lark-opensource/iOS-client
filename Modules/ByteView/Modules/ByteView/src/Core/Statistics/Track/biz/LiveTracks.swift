//
//  LiveTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class LiveTracks {

    static func trackPrivacyPolicyFromHostAlert() {
        trackFromHostAlert(actionName: "click_privacy_policy")
    }

    static func trackUserTermsFromHostAlert() {
        trackFromHostAlert(actionName: "click_user_terms_of_service")
    }

    static func trackRefuseFromHostAlert() {
        trackFromHostAlert(actionName: "refuse_host_live")
    }

    static func trackAgreeFromHostAlert() {
        trackFromHostAlert(actionName: "agree_host_live")
    }

    static func trackPrivacyPolicy(envId: String) {
        VCTracker.post(name: .vc_privacy_policy_popup, params: [.env_id: envId, .action_name: "click_privacy_policy"])
    }

    static func trackUserTerms(envId: String) {
        VCTracker.post(name: .vc_privacy_policy_popup, params: [.env_id: envId, .action_name: "click_user_terms_of_service"])
    }

    static func trackCancelLive(envId: String) {
        VCTracker.post(name: .vc_privacy_policy_popup, params: [.env_id: envId, .action_name: "cancal"])
    }

    static func trackJoinLive(envId: String) {
        VCTracker.post(name: .vc_privacy_policy_popup, params: [.env_id: envId, .action_name: "join"])
    }

    static func trackDisplayAlert(envId: String) {
        VCTracker.post(name: .vc_privacy_policy_popup, params: [.env_id: envId, .action_name: "display"])
    }

    static func trackCopyLiveStreamingLink() {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.action_name: "copy_livestreaminglink"])
    }

    static func trackAskingLiveAlert(isAgree: Bool) {
        VCTracker.post(name: .vc_begin_live_popup,
                       params: [.action_name: isAgree ? "agree" : "refuse"])
    }

    private static func trackFromHostAlert(actionName: String) {
        VCTracker.post(name: .vc_begin_live_popup,
                       params: [.action_name: actionName])
    }
}
