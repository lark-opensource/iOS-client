//
//  EntityTypeConfig.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/22.
//

import Foundation

// MARK: - Entity
public enum SearchEntityType: String, Codable {
    case chatter
    case chat
    case bot
    case thread
    case userGroup
    case doc
    case wiki
    case wikiSpace
    case myAi
    case mailUser
}

/// 过滤实体配置必须遵守该协议，表明该实体的类型
public protocol EntityConfigType { var type: SearchEntityType { get } }

/// user过滤实体必须遵守该协议,表明是user实体类型
public protocol ChatterEntityConfigType: EntityConfigType {}

/// chat过滤实体必须遵守该协议，表明是chat实体类型
public protocol GroupChatEntityConfigType: EntityConfigType {}

/// bot过滤实体必须遵守该协议，表明是bot实体类型
public protocol BotEntityConfigType: EntityConfigType {}

/// thread过滤实体必须遵守该协议，表明是thread实体类型
public protocol ThreadEntityConfigType: EntityConfigType {}

/// 静态用户组过滤实体必须遵守该协议，表明是静态用户组实体类型
public protocol UserGroupEntityConfigType: EntityConfigType {}

/// 动态用户组过滤实体必须遵守该协议，表明是动态用户组实体类型
public protocol DynamicUserGroupEntityConfigType: EntityConfigType {}

/// 文档过滤实体必须遵守该协议，表明是文档实体类型
public protocol DocEntityConfigType: EntityConfigType {}

/// wiki过滤实体必须遵守该协议，表明是wiki实体类型
public protocol WikiEntityConfigType: EntityConfigType {}

/// wiki space过滤实体必须遵守该协议，表明是wiki空间实体类型
public protocol WikiSpaceEntityConfigType: EntityConfigType {}

/// MyAi过滤实体必须遵守该协议，表明是MyAi空间实体类型
public protocol MyAiEntityConfigType: EntityConfigType {}

/// MailUser过滤实体必须遵守该协议，表明是MailUser空间实体类型（该实体搜索结果为开放搜索，且包含多个不同entity类型）
public protocol MailUserEntityConfigType: EntityConfigType {}

public extension ChatterEntityConfigType {
    var type: SearchEntityType { .chatter }
}

public extension GroupChatEntityConfigType {
    var type: SearchEntityType { .chat }
}

public extension BotEntityConfigType {
    var type: SearchEntityType { .bot }
}

public extension ThreadEntityConfigType {
    var type: SearchEntityType { .thread }
}

public extension UserGroupEntityConfigType {
    var type: SearchEntityType { .userGroup }
}

public extension DocEntityConfigType {
    var type: SearchEntityType { .doc }
}

public extension WikiEntityConfigType {
    var type: SearchEntityType { .wiki }
}

public extension WikiSpaceEntityConfigType {
    var type: SearchEntityType { .wikiSpace }
}

public extension MyAiEntityConfigType {
    var type: SearchEntityType { .myAi }
}

public extension MailUserEntityConfigType {
    var type: SearchEntityType { .mailUser }
}

public typealias IncludeConfigs = [EntityConfigType]

extension Collection where Element == EntityConfigType {
    public func getEntities<T>() -> [T] where T: EntityConfigType {
        let entities = self.compactMap { $0 as? T }
        validate(entities: entities)
        return entities
    }

    private func validate(entities: [EntityConfigType]) {
        assert(entities.count <= 1, "currently same type entity: \(entities.self) can only set once")
    }
}
