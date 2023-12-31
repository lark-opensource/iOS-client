//
//  Tags.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation

public struct NewDisplayTags: Codable {
    public let tagType: Int
    public let tagValue: String

    private enum CodingKeys: String, CodingKey {
        case tagType = "tag_type"
        case tagValue = "tag_value"
    }
}
