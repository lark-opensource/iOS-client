//
//  SCSettingService.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/11.
//

import SwiftyJSON
import LarkContainer
import RxSwift
import LarkSetting

public protocol RawSettings {
    var json: JSON { get }
}

public protocol SCSettingService: RawSettings {
    func contains(_ key: SCSettingKey) -> Bool
    func bool(_ key: SCSettingKey) -> Bool
    func int(_ key: SCSettingKey) -> Int
    func string(_ key: SCSettingKey) -> String
    func dictionary<T>(_ key: SCSettingKey) -> [String: T]
    func array<T>(_ key: SCSettingKey) -> [T]
}

public protocol SCRealTimeSettingService: SCSettingService {
    func registObserver(key: SCSettingKey, callback: ((Any?) -> Void)?) -> String
    func unregistObserver(identifier: String)
}

extension SCSettingService {
    func contains(_ key: SCSettingKey) -> Bool {
        json[key.rawValue].exists()
    }

    func bool(_ key: SCSettingKey) -> Bool {
        let defaultValue = getDefaultValue(key).or(false)
        return json[key.rawValue].bool.or(defaultValue)
    }

    func int(_ key: SCSettingKey) -> Int {
        let defaultValue = getDefaultValue(key).or(0)
        return json[key.rawValue].int.or(defaultValue)
    }

    func string(_ key: SCSettingKey) -> String {
        let defaultValue = getDefaultValue(key).or("")
        return json[key.rawValue].string.or(defaultValue)
    }

    func dictionary<T>(_ key: SCSettingKey) -> [String: T] {
        let defaultValue: [String: T] = getDefaultValue(key).or([:])
        return (json[key.rawValue].dictionaryObject as? [String: T]).or(defaultValue)
    }

    func array<T>(_ key: SCSettingKey) -> [T] {
        let defaultValue: [T] = getDefaultValue(key).or([])
        return (json[key.rawValue].arrayObject as? [T]).or(defaultValue)
    }
}

extension SCSettingService {
    private func getDefaultValue<T>(_ key: SCSettingKey) -> T? {
        guard let defaultValue = SCKeysDefaultConfig.config[key] as? T else {
            assertionFailure("did not registe default config in SCKeysDefaultConfig.config")
            return nil
        }
        return defaultValue
    }
}

public struct SCSettingKey: Hashable {
    public let rawValue: String
    public let version: String?
    public let owner: String?

    public init(rawValue: String, version: String, owner: String) {
        self.rawValue = rawValue
        self.version = version
        self.owner = owner
        SCLogger.info("construct settings key \(rawValue), online version \(version), key owner: \(owner)")
    }

    public static func == (lhs: SCSettingKey, rhs: SCSettingKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
