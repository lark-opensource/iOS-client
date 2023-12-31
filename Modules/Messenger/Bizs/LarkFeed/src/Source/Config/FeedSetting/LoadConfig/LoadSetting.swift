//
//  LoadSetting.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/18.
//

import Foundation
import LarkUIKit

struct LoadSetting: Codable, CustomStringConvertible {
    let buffer: Int
    let cache_total: Int
    let loadmore: Int
    let refresh: Int

    // 重构后，暂时未启用
    var safe_buffer: Int {
        max(0, min(buffer, LoadConfigInitial.buffer))
    }

    // 重构后，暂时未启用
    var safe_cache_total: Int {
        max(0, min(cache_total, LoadConfigInitial.firstScreen))
    }

    var safe_loadmore: Int {
        max(0, min(loadmore, LoadConfigInitial.loadMore))
    }

    var safe_refresh: Int {
        // iPad首屏至少20，不参与动态下发
        if Display.pad { return LoadConfigInitial.refresh }
        return max(0, min(refresh, LoadConfigInitial.refresh))
    }

    var description: String {
        "buffer: \(self.safe_buffer), "
            + "cache_total: \(self.safe_cache_total), "
            + "loadmore: \(self.safe_loadmore), "
            + "refresh: \(self.safe_refresh)"
    }
}
