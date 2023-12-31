//
//  EnterpriseCallTracks.swift
//  ByteView
//
//  Created by fakegourmet on 2022/2/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class EnterpriseCallTracks {
    private static let clickTab = TrackEventName.vc_tab_list_click
    /// 点击个人电话
    static func trackClickPersonalCall() {
        VCTracker.post(name: clickTab, params: [.click: "real_call"])
    }
}
