//
//  ClockInUtils.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/7/28.
//

import Foundation

/// iOS14 调用系统API 获取到的 bssid 可能是这个样子 b8:3a:5a:b4:3:92。当 ":" 中间的是一位时我们需要补0
struct MacAddressFormat {
    func format(_ macAddress: String) -> String {
        if macAddress.count <= 1 {
            return macAddress
        }
        let components = macAddress.split(separator: ":")
        guard components.count > 1 else {
            return macAddress
        }
        return components.map { $0.count == 1 ? "0\($0)" : $0 }.joined(separator: ":")
    }
}
