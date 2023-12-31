//
//  PrelobbyTracks.swift
//  ByteView
//
//  Created by liujianlong on 2021/1/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

enum PrelobbyTracks {

    private static let name = TrackEventName.vc_pre_waitingroom

    static func clickLeave() {
        VCTracker.post(name: name, params: [.action_name: "click_leave"])
        /// 新埋点
        VCTracker.post(name: .vc_meeting_pre_click,
                       params: [.click: "leave"])
    }

    static func clickBack() {
        VCTracker.post(name: name, params: [.action_name: "click_back"])
        /// 新埋点
        VCTracker.post(name: .vc_meeting_pre_click,
                       params: [.click: "close",
                                .is_starting_auth: true])
    }
}
