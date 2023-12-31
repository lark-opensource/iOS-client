//
//  MessageRequestConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct MessageRequestConfig: Decodable {
    /// 拉取时间间隔 毫秒
    private let imMessageComplete: UInt
    public var secondsDistance: TimeInterval {
        TimeInterval(imMessageComplete) / 1000
    }

    static let `default` = MessageRequestConfig(imMessageComplete: 5000)
}
