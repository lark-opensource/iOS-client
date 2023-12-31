//
//  SLATimeoutConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/5.
//

import Foundation

// disable-lint: magic number
public struct SLATimeoutConfig: Decodable {
    public let duration: Int
    public static let `default`: SLATimeoutConfig = SLATimeoutConfig(duration: 10000)
}
