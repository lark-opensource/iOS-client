//
//  AddBotPageDataModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import Foundation

/// 拉取可以加群的 bot 数据
struct AddBotPageDataModel: Codable {
    /// 可添加的bot列表
    let bots: [GroupBotModel]?
    /// 推荐的bot列表
    let recommendBots: [RecommendBotModel]?
    /// 客户端显示的最大bot数，上边list最多有这么多
    let maxBotNumber: Int?
    /// 同上，最大推荐bot数
    let maxRecommendBotNumber: Int?

    private enum CodingKeys: String, CodingKey {
        case bots = "bots"
        case recommendBots = "recommend_bots"
        case maxBotNumber = "max_bot_num"
        case maxRecommendBotNumber = "max_recommend_bot_num"
    }
}
