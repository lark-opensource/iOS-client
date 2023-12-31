//
//  BotModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/9.
//

import Foundation

/// 机器人model协议
protocol AbstractBotModel {
    var name: String? { get }
    var description: String? { get }
    var avatar: BotAvatarModel? { get }
}

/// 已安装的机器人model：拥有bot_id
struct GroupBotModel: Codable, AbstractBotModel {
    let botID: String?
    let functionalBotID: String?
    let botType: BotType

    let name: String?
    let description: String?
    let avatar: BotAvatarModel?

    /// 是否已添加
    let isInvited: Bool?
    /// 状态。0: 正常使用，其他：不可用，映射逻辑在rust-sdk
    let state: Int?

    private enum CodingKeys: String, CodingKey {
        case botID = "bot_id"
        case functionalBotID = "functional_bot_id"
        case botType = "bot_type"

        case name = "name"
        case description = "description"
        case avatar = "avatar"

        case isInvited = "is_invited"
        case state = "state"
    }
}

/// 没安装的机器人model：只有app_id，没有bot_id
struct RecommendBotModel: Codable, AbstractBotModel {
    let appID: String
    let botType: BotType

    let name: String?
    let description: String?
    let avatar: BotAvatarModel?

    /// 应用目录小程序的机器人详情页链接
    let detailMicroAppURL: String?
    /// 应用目录小程序机器人获取页链接
    let getMicroAppURL: String?

    private enum CodingKeys: String, CodingKey {
        case appID = "app_id"
        case botType = "bot_type"

        case name = "name"
        case description = "description"
        case avatar = "avatar"

        case detailMicroAppURL = "mobile_detail_micro_app_url"
        case getMicroAppURL = "mobile_get_micro_app_url"
    }
}

/// 机器人类型
enum BotType: Int, Codable {
    case chatBot = 0
    case functionalBot = 1
    case onCallBot = 2
}

/// 机器人头像数据相关
struct BotAvatarModel: Codable {
    let key: String
    let fsUnit: String?

    private enum CodingKeys: String, CodingKey {
        case key = "key"
        case fsUnit = "fs_unit"
    }
}
