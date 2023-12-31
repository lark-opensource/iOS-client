//
//  MagicShareDowngradeConfig.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/12/20.
//

import Foundation

// 妙享降级参数配置
// Settings地址：https://cloud.bytedance.net/appSettings-v2/detail/config/126750/detail/status
// disable-lint: magic number
public struct MagicShareDowngradeConfig: Decodable {
    public let degradeEnabled: Bool
    public let degradeSystemLoad: CGFloat
    public let degradeThermalFair: CGFloat
    public let degradeThermalSerious: CGFloat
    public let degradeThermalCritical: CGFloat
    public let degradeOpenDocInterval: CGFloat
    public let degradeOpenDocStep: CGFloat
    public let degradeDynamicHighCount: Int
    public let degradeDynamicLowCount: Int
    public let degradeDynamicStep: CGFloat
    public let degradeDynamicMax: CGFloat

    static let `default` = MagicShareDowngradeConfig(degradeEnabled: false,
                                                     degradeSystemLoad: 1.0,
                                                     degradeThermalFair: 0,
                                                     degradeThermalSerious: 1.0,
                                                     degradeThermalCritical: 2.0,
                                                     degradeOpenDocInterval: 30,
                                                     degradeOpenDocStep: 0.5,
                                                     degradeDynamicHighCount: 6,
                                                     degradeDynamicLowCount: 6,
                                                     degradeDynamicStep: 0.2,
                                                     degradeDynamicMax: 3.0)
}
