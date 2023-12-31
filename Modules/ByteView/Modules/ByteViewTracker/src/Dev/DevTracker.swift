//
//  DevTracker.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/17.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

/// 客户端自定义埋点，用于报警、Oncall效能等用途
/// - platform: tea
/// - event_name: vc_client_event_dev
/// - note: 性能监控目前有可感知耗时框架，不再在这里重复埋点
public final class DevTracker {
    public static func post(_ event: DevTrackEvent, file: String = #fileID, function: String = #function, line: Int = #line) {
        VCTracker.shared.track(event: event.toEvent(), for: [.tea], file: file, function: function, line: line)
    }
}
