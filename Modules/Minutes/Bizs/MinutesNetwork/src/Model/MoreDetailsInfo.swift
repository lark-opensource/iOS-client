//
//  MoreDetailsInfo.swift
//  MinutesFoundation
//
//  Created by sihuahao on 2021/7/2.
//

import Foundation

public struct MoreDetailsInfo: Codable {
    public let pageView: Int
    public let userView: Int
    public let reactionUserNum: Int
    public let commentNum: Int

    private enum CodingKeys: String, CodingKey {
        case pageView = "page_view"
        case userView = "user_view"
        case reactionUserNum = "reaction_user_num"
        case commentNum = "comment_num"
    }
}
