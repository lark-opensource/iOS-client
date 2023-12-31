//
//  LarkMagicTeaWhiteList.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/6.
//

import Foundation

typealias EventName = String
typealias EventParamKey = String
typealias EventParamAllowValues = [String]
typealias EventParamsConfig = [EventParamKey: EventParamAllowValues]
struct LarkMagicConfig: Codable {

    /// whiteList配置样例：
    /// white_list = {
    ///  "chat_view":{
    ///     "from": ["search","feed"]
    ///   }
    /// }
    let whiteList: [EventName: EventParamsConfig]
    let feelgoodAppKey: String
    let timeout: Int64 // 打开问卷超时时间，ms级

    enum CodingKeys: String, CodingKey {
        case whiteList = "white_list_with_params"
        case feelgoodAppKey = "feelgood_app_key"
        case timeout = "timeout"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        whiteList = try container.decode([EventName: EventParamsConfig].self, forKey: CodingKeys.whiteList)
        feelgoodAppKey = try container.decode(String.self, forKey: CodingKeys.feelgoodAppKey)
        timeout = try container.decode(Int64.self, forKey: CodingKeys.timeout)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(whiteList, forKey: CodingKeys.whiteList)
        try container.encode(feelgoodAppKey, forKey: CodingKeys.feelgoodAppKey)
        try container.encode(timeout, forKey: CodingKeys.timeout)
    }
}
