//
//  MemoryUsage.swift
//  ByteView
//
//  Created by liujianlong on 2021/6/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

extension ByteViewMemoryUsage {
    static func getCurrentMemoryUsage() -> ByteViewMemoryUsage {
        if #available(iOS 12.0, *), let usage = VCTracker.shared.getCurrentMemoryUsage() {
            return ByteViewMemoryUsage(appUsageBytes: Int64(usage.appUsageBytes), systemUsageBytes: Int64(usage.systemUsageBytes), availableUsageBytes: Int64(usage.availableUsageBytes))
        } else {
            // iOS11调用hmd_getMemoryBytes可能会卡死1s，详见方法实现
            return byteview_current_memory_usage()
        }
    }
}
