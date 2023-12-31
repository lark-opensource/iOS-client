//
//  ShortcutConfig.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation

public struct ShortcutConfig: Codable, CustomStringConvertible {
    public var actionConfig: ActionConfig = ActionConfig()
    public var bizConfigs: [String: BizConfig] = [:]

    private init() {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.actionConfig = try container.decode(ActionConfig.self, forKey: .actionConfig, defaultValue: ActionConfig())
        self.bizConfigs = try container.decode([String: BizConfig].self, forKey: .bizConfigs, defaultValue: [:])
    }

    public var description: String {
        "ShortcutConfig(actionConfig: \(actionConfig), bizConfigs: \(bizConfigs))"
    }

    public struct BizConfig: Codable, CustomStringConvertible {
        public var isDisableAll = false
        public var disabledActions: Set<ShortcutAction.Identifier> = []

        fileprivate init() {}
        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            self.isDisableAll = try container.decode(Bool.self, forKey: .isDisableAll, defaultValue: false)
            self.disabledActions = try container.decode(Set<ShortcutAction.Identifier>.self, forKey: .disabledActions, defaultValue: [])
        }

        public var description: String {
            "BizConfig(isDisableAll: \(isDisableAll), disabledActions: \(disabledActions))"
        }
    }

    public struct ActionConfig: Codable, CustomStringConvertible {
        public var disabledActions: Set<ShortcutAction.Identifier> = []

        fileprivate init() {}

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            self.disabledActions = try container.decode(Set<ShortcutAction.Identifier>.self, forKey: CodingKeys.disabledActions, defaultValue: [])
        }

        public var description: String {
            "ActionConfig(disabledActions: \(disabledActions))"
        }
    }

    public static let none = ShortcutConfig()
}

private extension KeyedDecodingContainer {
    func decode(_ type: Bool.Type, forKey key: Self.Key, defaultValue: Bool) throws -> Bool {
        try decodeIfPresent(type, forKey: key) ?? defaultValue
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Self.Key, defaultValue: T) throws -> T {
        try decodeIfPresent(type, forKey: key) ?? defaultValue
    }
}
