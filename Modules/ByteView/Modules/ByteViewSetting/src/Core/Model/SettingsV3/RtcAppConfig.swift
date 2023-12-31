//
//  RtcAppConfig.swift
//  ByteView
//
//  Created by ZhangJi on 2023/2/21.
//

import Foundation

public struct RtcAppConfig: Decodable {
    public let rtcAppid: String // rtc AppId

    static let `default` = RtcAppConfig(rtcAppid: "5b978bab09b27c0034d252c0")
}
