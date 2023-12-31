//
//  MicVolumeConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct MicVolumeConfig: Decodable {
    public let levels: [Int]
    public let animatedVolume: Int

    public static let `default` = MicVolumeConfig(levels: [0, 130, 180, 220, 255], animatedVolume: 40)

    // 目前其他端暂不支持动态改变动画等级的数量，因此这里固定写死 5 个等级
    private static let numberOfLevels = 5
    private static let minVolume = 0
    private static let maxVolume = 255
    var isValid: Bool {
        // 1. 配置的数量必须是 5
        if levels.count != Self.numberOfLevels {
            return false
        }
        // 2. 第一个必须是 0，最后一个必须是 255
        if levels.first != Self.minVolume || levels.last != Self.maxVolume {
            return false
        }
        // 3. 必须是严格增序
        if levels.sorted(by: <) != levels {
            return false
        }
        // 4. 中间值必须超过 step
        if levels[1] - animatedVolume < 0 {
            return false
        }
        return true
    }
}
