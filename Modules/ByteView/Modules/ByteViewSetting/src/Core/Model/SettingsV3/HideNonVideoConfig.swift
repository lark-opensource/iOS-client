//
//  HideNonVideoConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public struct HideNonVideoConfig: Decodable {
    public let period: Double

    static let `default` = HideNonVideoConfig(period: 15000)
}
