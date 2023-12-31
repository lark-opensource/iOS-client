//
//  TrackPrivacy.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension DevTrackEvent {

    /// 隐私安全
    public enum Privacy: String {
        /// rtc 释放过慢导致客户端提前离开隐私检测白名单，可能产生敏感 API 未配对调用的误报
        case leave_channel_too_slow
        /// 监测到麦摄状态 rtc 与其他两端不一致，且当前设备 total CPU 占用过高时
        case total_cpu_overload_on_unsync_check
    }

}
