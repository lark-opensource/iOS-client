//
//  PickerSearchConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/4/7.
//

import Foundation
import RustPB

public struct PickerSearchConfig: Codable {
    public var entities: [EntityConfigType] = [
        PickerConfig.ChatterEntityConfig(),
        PickerConfig.ChatEntityConfig()
    ]
    /// 搜索指定群内的数据
    public var chatId: String?
    public var permissions: [RustPB.Basic_V1_Auth_ActionType]?
    var name: String = ""
    // 部分场景需要设置服务端规定的场景值，供服务端搜索策略和打点使用
    public var scene: String = ""

    public init(entities: [EntityConfigType] = [],
                scene: String = "",
                chatId: String? = nil,
                permission: [RustPB.Basic_V1_Auth_ActionType]? = nil) {
        self.entities = entities
        self.chatId = chatId
        self.permissions = permission
        self.scene = scene
    }

    public enum CodingKeys: String, CodingKey {
        case entities
        case chatId
        case permissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PickerSearchConfig.CodingKeys.self)
        self.chatId = try? container.decode(String.self, forKey: .chatId)
        self.permissions = try? container.decode([RustPB.Basic_V1_Auth_ActionType].self, forKey: .permissions)
        let wrapper = try container.decode(EntityConfigWrapper.self, forKey: .entities)
        self.entities = wrapper.entities
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:CodingKeys.self)
        let wrapper = EntityConfigWrapper(entities: self.entities)
        try container.encode(wrapper, forKey: .entities)
        try container.encode(self.chatId, forKey: .chatId)
        try container.encode(self.permissions, forKey: .permissions)
    }
}

extension RustPB.Basic_V1_Auth_ActionType: Codable {}

struct EntityConfigWrapper: Codable {
    var chatters: [PickerConfig.ChatterEntityConfig] = []
    var chats: [PickerConfig.ChatEntityConfig] = []
    var userGroups: [PickerConfig.UserGroupEntityConfig] = []
    var docs: [PickerConfig.DocEntityConfig] = []
    var wikis: [PickerConfig.WikiEntityConfig] = []
    var wikiSpaces: [PickerConfig.WikiSpaceEntityConfig] = []

    init(entities: [EntityConfigType]) {
        entities.forEach {
            if let i = $0 as? PickerConfig.ChatterEntityConfig {
                self.chatters.append(i)
            } else if let i = $0 as? PickerConfig.ChatEntityConfig {
                self.chats.append(i)
            } else if let i = $0 as? PickerConfig.UserGroupEntityConfig {
                self.userGroups.append(i)
            } else if let i = $0 as? PickerConfig.DocEntityConfig {
                self.docs.append(i)
            } else if let i = $0 as? PickerConfig.WikiEntityConfig {
                self.wikis.append(i)
            } else if let i = $0 as? PickerConfig.WikiSpaceEntityConfig {
                self.wikiSpaces.append(i)
            }
        }
    }

    var entities: [EntityConfigType] {
        var result = [EntityConfigType]()
        result.append(contentsOf: chatters)
        result.append(contentsOf: chats)
        result.append(contentsOf: userGroups)
        result.append(contentsOf: docs)
        result.append(contentsOf: wikis)
        result.append(contentsOf: wikiSpaces)
        return result
    }
}
