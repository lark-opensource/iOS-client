//
//  FloatReactionConfig.swift
//  ByteViewSetting
//
//  Created by YizhuoChen on 2023/11/7.
//

import Foundation

// disable-lint: magic number
public struct FloatReactionConfig: Decodable {
    /// 表情动画持续时间，单位毫秒
    public let duration: Int

    /// 最多展示的表情数量为 screenWidth * screenHeight / displayDensity
    public let displayDensity: Int

    /// [0, 1], 表情动画向上位移为 screenHeight * heightRatio
    public let heightRatio: CGFloat

    /// 新版表情开关
    public let isEnabled: Bool

    static let `default` = FloatReactionConfig(duration: 3500, displayDensity: 5580, heightRatio: 0.25, isEnabled: true)
}
