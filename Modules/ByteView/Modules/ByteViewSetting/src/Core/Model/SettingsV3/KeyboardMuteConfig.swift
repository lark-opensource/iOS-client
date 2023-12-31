//
//  KeyboardMuteConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct KeyboardMuteConfig: Decodable {
    public let longPressDuration: Int
    static let `default` = KeyboardMuteConfig(longPressDuration: 500)
}
