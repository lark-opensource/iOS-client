//
//  MutePromptConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct MutePromptConfig: Decodable {
    public let interval: Int // SDK回调声音的时间间隔 ms
    public let level: Int // SDK检测音量的阈值

    static let `default` = MutePromptConfig(interval: 400, level: 80)
}
