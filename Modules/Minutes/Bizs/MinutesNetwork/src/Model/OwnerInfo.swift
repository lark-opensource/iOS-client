//
//  OwnerInfo.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/1/19.
//

import Foundation

public struct OwnerInfo: Codable {
    public let userId: String
    public let userType: Int
    public let userName: String
    public let avatarURL: String
    public let avatarKey: String

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userType = "user_type"
        case userName = "user_name"
        case avatarURL = "avatar_url"
        case avatarKey = "avatar_key"
    }
}
