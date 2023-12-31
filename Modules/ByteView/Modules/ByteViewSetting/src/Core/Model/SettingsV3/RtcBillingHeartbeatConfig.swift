//
//  RtcBillingHeartbeatConfig.swift
//  ByteView
//
//  Created by yangyao on 2023/3/3.
//

import Foundation

public struct RtcBillingHeartbeatConfig: Decodable {
    public let enabled: Bool
    public let interval: Int

    static let `default` = RtcBillingHeartbeatConfig(enabled: false, interval: 60)
}
