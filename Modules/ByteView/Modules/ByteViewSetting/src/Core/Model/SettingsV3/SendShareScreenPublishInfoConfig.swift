//
//  SendShareScreenPublishInfoConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct SendShareScreenPublishInfoConfig: Decodable {
    public let sendShareScreenIntervalMs: Int
    static let `default` = SendShareScreenPublishInfoConfig(sendShareScreenIntervalMs: 10000)
}
