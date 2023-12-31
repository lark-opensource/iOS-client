//
//  PickerConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/18.
//

import Foundation

public struct PickerConfig {}
public protocol PickerContentConfigType {}

extension PickerConfig {
    public struct ChatterField: Codable {
        /// 配置相应的会话id, 返回是否存在于会话中: isInChat
        public let chatIds: [String]?
        /// 配置相应的团队id, 返回是否直属于团队: isDirectlyInTeam
        public let directlyTeamIds: [String]?
        /// 是否需要返回人的协作关系标签信息：包括外部、b2b自定义等
        public var relationTag: Bool = true
        
        public init(chatIds: [String]? = nil, directlyTeamIds: [String]? = nil) {
            assert((chatIds?.count ?? 0) <= 1, "Currently only supports specifying one chat")
            assert((directlyTeamIds?.count ?? 0) <= 1, "Currently only supports specifying one teamId")
            self.chatIds = chatIds
            self.directlyTeamIds = directlyTeamIds
        }
    }
}

extension PickerConfig {
    public struct ChatField: Codable {
        public var relationTag: Bool = false
        /// 配置相应的团队id, 返回是否直属于团队: isDirectlyInTeam
        public var directlyTeamIds: [String]?
        public var showEnterpriseMail: Bool = false
        public init(relationTag: Bool = false, showEnterpriseMail: Bool = false, directlyTeamIds: [String]? = nil) {
            self.relationTag = relationTag
            self.showEnterpriseMail = showEnterpriseMail
            assert((directlyTeamIds?.count ?? 0) <= 1, "Currently only supports specifying a teamId")
            self.directlyTeamIds = directlyTeamIds
        }
    }
}

public protocol PickerChatterFieldConfigurable: Codable {
    var field: PickerConfig.ChatterField? { get set }
}
public protocol PickerChatFieldConfigurable: Codable {
    var field: PickerConfig.ChatField? { get set }
}

public extension PickerConfig {
    struct ChatterContent: ChatterEntityConfigType, PickerChatterFieldConfigurable {
        public var field: PickerConfig.ChatterField?
        public init(field: PickerConfig.ChatterField? = nil) {
            self.field = field
        }
    }
    
    struct ChatContent: ChatterEntityConfigType, PickerChatFieldConfigurable {
        public var field: PickerConfig.ChatField? = nil
        public init(field: PickerConfig.ChatField? = nil) {
            self.field = field
        }
    }
}
extension PickerConfig.ChatterContent: PickerContentConfigType {}
extension PickerConfig.ChatContent: PickerContentConfigType {}

public extension Collection where Element == PickerContentConfigType {
    func getEntities<T>() -> [T] where T: PickerContentConfigType {
        return compactMap { $0 as? T }
    }
}
