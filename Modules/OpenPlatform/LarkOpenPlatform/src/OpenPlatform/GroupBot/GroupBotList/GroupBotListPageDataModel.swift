//
//  GroupBotListPageDataModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import Foundation

/// 「群机器人」页面 bot 数据
struct GroupBotListPageDataModel: Codable {
    /// 可添加的bot列表
    let bots: [GroupBotModel]?
    /// 客户端显示的最大bot数，上边list最多有这么多
    let maxBotNumber: Int?

    private enum CodingKeys: String, CodingKey {
        case bots = "bots"
        case maxBotNumber = "max_bot_num"
    }
}
