//
//  InMeetFullScreenTracks.swift
//  ByteView
//
//  Created by liujianlong on 2021/11/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewUI

// 自动隐藏工具栏，埋点 https://bytedance.feishu.cn/sheets/shtcnp3y1FuDaaXT54N21I9lL6e
// 注：“额外参数”与“第一参数”在上报时，平铺在params里面

enum InMeetFullScreenTracks {
    static func trackClickAutoHideToolBar(isCheck: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "auto_hide_toolbar", "is_check": isCheck])
    }

    static func trackFullScreenClickMic(option: Bool, isSharing: Bool, shareType: String) {
        var params: TrackParams = [
            "is_sharing": isSharing,
            "share_type": shareType,
            .click: "mic_in_immersed_status",
            .option: option ? "open" : "close"
        ]
        if Display.phone {
            params["is_screen_horizontal"] = VCScene.isLandscape
        }
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    static func trackPhoneFullScreenWakeUpToolbar(isSharing: Bool, shareType: String) {
        var params: TrackParams = [
            "is_sharing": isSharing,
            "share_type": shareType,
            .click: "wake_up_toolbar"
        ]
        if Display.phone {
            params["is_screen_horizontal"] = VCScene.isLandscape
        }
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    static func trackPadFullScreenUnfoldToolbar(isSharing: Bool, shareType: String) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [
                        "is_sharing": isSharing,
                        "share_type": shareType,
                        .click: "unfold_toolbar"
                       ])
    }

}
