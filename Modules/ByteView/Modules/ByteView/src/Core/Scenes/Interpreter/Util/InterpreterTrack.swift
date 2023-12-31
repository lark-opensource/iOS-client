//
//  InterpreterTrack.swift
//  ByteView
//
//  Created by yangfukai on 2020/10/30.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class InterpreterTrack {
    private static let settingPage = TrackEventName.vc_meeting_page_setting
    private static let onTheCallPage = TrackEventName.vc_meeting_page_onthecall

    // 点击meetSetting上的选项
    static func clickToolBar() {
        VCTracker.post(name: onTheCallPage,
                       params: [.from_source: "control_bar",
                                .action_name: "click_interpretation"])
    }

    static func switchLanguage() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "switch_language"])
    }

    static func startInterpretation() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "start_interpretation"])
    }

    static func setInterpreter(uid: String, deviceId: String) {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "assign_interpreter",
                                .extend_value: ["attendee_uuid": EncryptoIdKit.encryptoId(uid),
                                                "attendee_device_id": deviceId]])
    }
}

// MARK: New Trackers
final class InterpreterTrackV2 {

    /// 同声传译页展示
    static func trackEnterInterpereterPage() {
        VCTracker.post(name: .vc_meeting_interpretation_view)
    }

    /// 点击开始同传
    static func trackClickStartInterpreter() {
        VCTracker.post(name: .vc_meeting_interpretation_click,
                       params: [.click: "start_interpretation"])
    }

}
