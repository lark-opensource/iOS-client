//
//  VideoSortConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct VideoSortConfig: Decodable {
    public let timeScope: UInt
    public let maxIndex: UInt
    public let factorAS: Float
    public let factorIndex: Float
    public let factorCamera: Float

    static let `default` = VideoSortConfig(timeScope: 120, maxIndex: 5, factorAS: 1, factorIndex: 3, factorCamera: 1)
}
