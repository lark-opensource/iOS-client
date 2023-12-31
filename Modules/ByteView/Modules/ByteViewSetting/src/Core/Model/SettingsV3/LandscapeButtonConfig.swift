//
//  LandscapeButtonConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

/// 视频会议横屏按钮显示版本控制配置
// disable-lint: magic number
public struct LandscapeButtonConfig: Decodable {
    /// 开放button的系统版本号
    public let iosVersion: String

    static let `default` = LandscapeButtonConfig(iosVersion: "98.1")
}
