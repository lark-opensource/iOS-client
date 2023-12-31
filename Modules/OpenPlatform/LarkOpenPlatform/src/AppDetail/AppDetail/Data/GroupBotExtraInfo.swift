//
//  GroupBotExtraInfo.swift
//  LarkAppCenter
//
//  Created by houjihu on 2021/6/15.
//

import Foundation

/// 后端接口方案：https://bytedance.feishu.cn/docs/doccnPWkzMJ1E1cSAwr6YXOvjvd#
/// 通用抽象机器人补充信息
protocol AbstractBotExtraInfo: Codable {
    /// 添加者
    var inviterName: String? { get }
    /// 添加者ID
    var inviterID: String? { get }
    /// 是否展示权限设置开关
    var showCheckMender: Bool? { get }
    /// 是否校验仅群主或 bot 添加者可以修改 bot 信息，默认值为否
    /// true/false代表权限设置开关状态
    var checkMender: Bool? { get }
    /// 是否无权限查看，同时也表示有没有权限删除或编辑
    var noPermission: Bool? { get }
}

/// webhook机器人补充信息
struct WebhookBotExtraInfo: Codable, AbstractBotExtraInfo {
    /// 添加者
    let inviterName: String?
    /// 添加者ID
    let inviterID: String?
    /// 是否展示权限设置开关
    var showCheckMender: Bool?
    /// 是否校验仅群主或 bot 添加者可以修改 bot 信息，默认值为否
    let checkMender: Bool?
    /// 是否无权限查看，同时也表示有没有权限删除或编辑
    let noPermission: Bool?
    enum CodingKeys: String, CodingKey {
        case inviterName = "inviter_name"
        case inviterID = "inviter_id"
        case showCheckMender = "show_check_mender"
        case checkMender = "check_mender"
        case noPermission = "no_permission"
    }
}

/// 应用机器人补充信息
struct AppBotExtraInfo: Codable, AbstractBotExtraInfo {
    struct Field: Codable {
        let fieldKey: String
        let fieldValue: String?
        let defaultValue: String?
        enum CodingKeys: String, CodingKey {
            case fieldKey = "field_key"
            case fieldValue = "field_value"
            case defaultValue = "default_value"
        }
    }
    private let fields: [Field]?
    /// 添加者
    private(set) var inviterName: String?
    /// 添加者ID
    private(set) var inviterID: String?
    /// 是否展示权限设置开关
    let showCheckMender: Bool?
    /// 是否校验仅群主或 bot 添加者可以修改 bot 信息，默认值为否
    private(set) var checkMender: Bool?
    /// 是否无权限查看，同时也表示有没有权限删除或编辑
    let noPermission: Bool?
    enum CodingKeys: String, CodingKey {
        case noPermission = "no_permission"
        case showCheckMender = "show_check_mender"
        case fields = "fields"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        noPermission = try? container.decode(Bool.self, forKey: .noPermission)
        showCheckMender = try? container.decode(Bool.self, forKey: .showCheckMender)
        fields = try? container.decode([Field].self, forKey: .fields)
        fields?.forEach({ (kv) in
            if kv.fieldKey == "check_mender", let value = kv.defaultValue {
                let obj = Bool(value) ?? false
                checkMender = obj
            } else if kv.fieldKey == "inviter_name" {
                inviterName = kv.fieldValue
            } else if kv.fieldKey == "inviter_id" {
                inviterID = kv.fieldValue
            }
        })
    }
}
