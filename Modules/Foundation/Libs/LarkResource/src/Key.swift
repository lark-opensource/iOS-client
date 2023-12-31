//
//  Key.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

/// 基础 key
public struct BaseKey: Hashable {
    /// Key extension 类型
    /// 不同的 type 会自动拼装不同的后缀
    public struct ExtensionType: Hashable {
        public var rawValue: String
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public static let image: ExtensionType = ExtensionType("image")
        public static let audio: ExtensionType = ExtensionType("audio")
        public static let color: ExtensionType = ExtensionType("color")
    }

    public var key: String
    public var extensionType: ExtensionType

    public init(key: String, extensionType: ExtensionType) {
        self.key = key
        self.extensionType = extensionType
    }

    /// 资源完整 key，用户在索引表中查找数据
    public var fullKey: String {
        let extensionStr = self.extensionType.rawValue
        if extensionStr.isEmpty {
            return self.key
        } else {
            return "\(self.key).\(extensionStr)"
        }
    }
}

/// 完整的资源key
public struct ResourceKey: Hashable {
    public var baseKey: BaseKey
    public var env: Env

    public init(baseKey: BaseKey, env: Env) {
        self.baseKey = baseKey
        self.env = env
    }
}

extension ResourceKey {

    public static func key(_ key: String, type: String, env: Env? = nil) -> ResourceKey {
        return ResourceKey(
            baseKey: BaseKey(
                key: key,
                extensionType: BaseKey.ExtensionType(type)
            ),
            env: env ?? Env()
        )
    }

    public static func image(key: String, env: Env? = nil) -> ResourceKey {
        return ResourceKey(
            baseKey: BaseKey(key: key, extensionType: .image),
            env: env ?? Env()
        )
    }

    public static func color(key: String, env: Env? = nil) -> ResourceKey {
        return ResourceKey(
            baseKey: BaseKey(key: key, extensionType: .color),
            env: env ?? Env()
        )
    }
}
