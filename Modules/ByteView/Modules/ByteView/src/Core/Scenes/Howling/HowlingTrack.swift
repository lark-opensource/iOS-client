//
//  HowlingTrack.swift
//  ByteView
//
//  Created by wulv on 2021/8/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

struct HowlingTrack {

    static func showAlert() {
        VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "recommend_mute"])
    }

    static func muteForAlert() {
        VCTracker.post(name: .vc_meeting_popup_click, params: [.content: "recommend_mute", .click: "mute"])
    }

    static func ignoreForAlert() {
        VCTracker.post(name: .vc_meeting_popup_click, params: [.content: "recommend_mute", .click: "ignore"])
    }
}
