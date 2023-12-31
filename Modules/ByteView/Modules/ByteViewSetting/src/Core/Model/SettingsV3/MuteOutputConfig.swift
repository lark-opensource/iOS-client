//
//  MuteOutputConfig.swift
//  ByteViewSetting
//
//  Created by chentao on 2023/6/9.
//

import Foundation

public struct MuteOutputConfig: Decodable {
    public let disableVersion: String
    static let `default` = MuteOutputConfig(disableVersion: "17.0")
}
