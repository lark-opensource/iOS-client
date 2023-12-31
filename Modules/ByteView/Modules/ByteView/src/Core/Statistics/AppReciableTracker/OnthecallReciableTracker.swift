//
//  OnthecallReciableTracker.swift
//  ByteView
//
//  Created by chentao on 2021/3/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class OnthecallReciableTracker {
    static func startEnterOnthecall() {
        LarkAppreciableTracker.shared.start(scene: .VCOnTheCall, event: .vc_enter_onthecall_total)
        InMeetPerfMonitor.startCollectOnthecallCPUs()
    }

    static func startEnterOnthecallForPure() {
        LarkAppreciableTracker.shared.start(scene: .VCOnTheCall, event: .vc_enter_onthecall_pure)
    }

    static func endEnterOnthecall() {
        LarkAppreciableTracker.shared.end(event: .vc_enter_onthecall_total)
        InMeetPerfMonitor.endCollectOnthecallCPUs()
    }

    static func endEnterOnthecallForPure() {
        LarkAppreciableTracker.shared.end(event: .vc_enter_onthecall_pure)
    }

    static func cancelStartOnthecall() {
        LarkAppreciableTracker.shared.cancel(event: .vc_enter_onthecall_total)
    }

    static func startConnectRtc(isCall: Bool) {
        LarkAppreciableTracker.shared.start(scene: .VCOnTheCall, event: .vc_rtc_connect_time, extraCategory: ["is_call": isCall.description])
    }

    static func endConnectRtc() {
        LarkAppreciableTracker.shared.end(event: .vc_rtc_connect_time)
    }

    static func startOpenCamera() {
        LarkAppreciableTracker.shared.start(scene: .VCOnTheCall, event: .vc_open_camera_time)
    }

    static func endOpenCamera() {
        LarkAppreciableTracker.shared.end(event: .vc_open_camera_time)
    }

    static func startEnterImChat() {
        LarkAppreciableTracker.shared.start(scene: .VCOnTheCall, event: .vc_enter_chat_window)
    }

    static func endEnterImChat(isGroupExist: Bool, meetingId: String, meetingType: Int, networkRequest: Int, openImWindow: Int) {
        let extraInfo: [String: Any] = ["is_group_exist": isGroupExist, "meeting_id": meetingId, "meeting_type": meetingType]
        let latencyDetail: [String: Any] = ["network_request": networkRequest, "open_im_window": openImWindow]
        LarkAppreciableTracker.shared.end(event: .vc_enter_chat_window, extraInfo: extraInfo, latencyDetail: latencyDetail)
    }

    static func enterImChatError(meetingId: String, errorCode: Int, errorMessage: String) {
        let extraInfo = ["meeting_id": meetingId]
        LarkAppreciableTracker.shared.error(scene: .VCOnTheCall, event: .vc_enter_chat_window, errorType: .Network, errorLevel: .Exception, errorCode: errorCode, errorMessage: errorMessage, extraInfo: extraInfo)
    }
}
