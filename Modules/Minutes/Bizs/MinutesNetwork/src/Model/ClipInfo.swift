//
//  ClipInfo.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/1/19.
//

import Foundation

public struct ClipInfo: Codable {
    public let isClip: Bool
    public let continuous: Bool
    public let isClipCreator: Bool
    public let clipNumber: Int
    public let parentURLStr: String

    private enum CodingKeys: String, CodingKey {
        case isClip = "is_clip"
        case continuous = "continuous"
        case isClipCreator = "is_clip_creator"
        case clipNumber = "clip_num"
        case parentURLStr = "parent_url"
    }
}
