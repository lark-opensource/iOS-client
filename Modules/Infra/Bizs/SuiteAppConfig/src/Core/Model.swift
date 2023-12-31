//
//  Model.swift
//  SuiteAppConfig
//
//  Created by liuwanlin on 2020/3/3.
//

import Foundation

open class BaseConfig {
    public private(set) var key: String

    public private(set) var traits: [String: Any] = [:]

    /// Get trait of key
    /// - Parameters:
    ///   - key: trait key
    ///   - decode: custom decode callback
    public func trait<T>(for key: String, decode: ((Any) -> T)? = nil) -> T? {
        if let decode = decode, let value = traits[key] {
            return decode(value)
        }
        return traits[key] as? T
    }

    public init(key: String, traits: String) throws {
        self.key = key
        let traits = traits.trimmingCharacters(in: .whitespaces).isEmpty ? "{}" : traits
        if let data = traits.data(using: .utf8) {
            do {
                if let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self.traits = obj
                } else {
                    throw AppConifgError.traitsNotDictionary(key: key)
                }
            } catch {
                throw AppConifgError.decodeTraitsFailed(key: key)
            }
        } else {
            throw AppConifgError.errorEncodingOfRawTraits(key: key)
        }
    }
}

public final class Feature: BaseConfig {
    public private(set) var isOn: Bool

    public init(key: String, feature: FeatureConf) throws {
        self.isOn = feature.isOn
        try super.init(key: key, traits: feature.traits)
    }
}

public enum AppConifgError: LocalizedError {
    /// Fail to decode traits from raw string
    case decodeTraitsFailed(key: String)
    /// Cannot convert traits to dictionary
    case traitsNotDictionary(key: String)
    /// The encoding of the raw traits string is not in the right format
    case errorEncodingOfRawTraits(key: String)
    /// Fail to encode traits from raw string
    case encodeTraitsFailed(key: String)
}

extension AppConifgError {
    public var errorDescription: String? {
        switch self {
        case .decodeTraitsFailed(key: let key):
            return "Fail to decode traits from raw string for feature \(key)"
        case .traitsNotDictionary(key: let key):
            return "Cannot convert traits to dictionary for feature \(key)"
        case .errorEncodingOfRawTraits(key: let key):
            return "The encoding of the raw traits string is not in the right format for feature \(key)"
        case .encodeTraitsFailed(let key):
            return "Fail to encode traits from raw string for feature \(key)"
        }
    }
}

enum FeatureKey: String {
    case leanMode = "leanMode"
}
