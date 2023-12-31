//
//  MeetingShareAudioConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

/// 会议共享屏幕是否开启共享音频配置，https://cloud.bytedance.net/appSettings/config/124305/detail/status
public struct MeetingShareAudioConfig: Decodable {
    /// 是否默认打开共享音频
    public let isOpenAudioShare: Bool

    static let `default` = MeetingShareAudioConfig(isOpenAudioShare: false)
}
