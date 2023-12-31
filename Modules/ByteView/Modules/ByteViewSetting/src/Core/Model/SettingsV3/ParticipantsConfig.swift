//
//  ParticipantsConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

/// 参会人技术侧的相关控制
/// 飞书 https://cloud.bytedance.net/appSettings-v2/detail/config/159498/detail/basic
/// Lark https://cloud.bytedance.net/appSettings-v2/detail/config/176278/detail/basic
/// 建议/拒绝列表限频是另一个全端配置
/// https://cloud.bytedance.net/appSettings-v2/detail/config/169800/detail/status
public struct ParticipantsConfig: Decodable {

    /// 全部tab列表刷新频控（毫秒）
    public let allTabReladMilliseconds: Int
    /// 参会人(会中&邀请)VM构造频控
    public let participantConsumeMillisecond: Int
    /// 等候室VM构造频控
    public let lobbyConsumeMillisecond: Int
    /// 观众VM构造频控
    public let attendeeConsumeMillisecond: Int

    static let `default` = ParticipantsConfig(allTabReladMilliseconds: 0, participantConsumeMillisecond: 0,
                                              lobbyConsumeMillisecond: 0, attendeeConsumeMillisecond: 0)
}
