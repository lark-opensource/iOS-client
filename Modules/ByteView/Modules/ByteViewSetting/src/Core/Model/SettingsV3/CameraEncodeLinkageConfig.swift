//
//  CameraEncodeLinkageConfig.swift
//  ByteViewSetting
//
//  Created by ByteDance on 2023/7/26.
//

import Foundation

// disable-lint: magic number
public struct CameraEncodeLinkageConfig: Decodable {
    // 帧率联动开关
    public let fpsLinkageEnable: Bool
    // 总计档位数量
    public let levelsCount: Int
    // 小视图基准档位
    public let smallViewBaseIndex: Int
    // 大视图 pixel
    public let bigViewPixels: Int
    // 大视图基准档位
    public let bigViewBaseIndex: Int
    // 单个特效降级档位
    public let singleEffectLevel: Int
    // 组合特效降级档位
    public let groupEffectLevel: Int
    // 节能模式降级档位
    public let ecoModeLevel: Int


    // disable-lint: magic number
    static let `default` = CameraEncodeLinkageConfig(fpsLinkageEnable: true,
                                                     levelsCount: 12,
                                                     smallViewBaseIndex: 0,
                                                     bigViewPixels: 518400,
                                                     bigViewBaseIndex: 6,
                                                     singleEffectLevel: 1,
                                                     groupEffectLevel: 2,
                                                     ecoModeLevel: 3)
    // enable-lint: magic number
}
