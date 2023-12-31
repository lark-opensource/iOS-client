//
//  DictionaryDecoder.swift
//  Pods
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

open class DictionaryDecoder: Decoder {
    public enum KeyDecodingStrategy {

        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key
        /// with the one specified by each type.
        case convertFromSnakeCase
    }

    public enum DecodeTypeStrategy {
        /// Use the strict mode when decoding values. The type of value must match exactly.
        case strict
        /// Use the loose mode when decoding values. The type of value can be convert from string or other types.
        case loose
    }

    public var codingPath: [CodingKey] = []

    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    public var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys

    /// The strategy to use for decoding of value types. Defaults to `.strict`.
    public var decodeTypeStrategy: DecodeTypeStrategy = .strict

    var storage = Storage()

    /// Initializes `self` with default strategies.
    public init() {}

    init(container: Any, codingPath: [CodingKey] = []) {
        storage.push(container: container)
        self.codingPath = codingPath
    }

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = try lastContainer(forType: [String: Any].self)
        return KeyedDecodingContainer(
            KeyedContainer(
                decoder: self,
                container: try unboxRawType(container, as: [String: Any].self)
            )
        )
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let container = try lastContainer(forType: [Any].self)
        return UnkeyedContanier(
            decoder: self,
            container: try unboxRawType(container, as: [Any].self)
        )
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueContainer(decoder: self)
    }

    func unboxRawType<T>(_ value: Any, as type: T.Type) throws -> T {
        let description = "Expected to decode \(type) but found \(Swift.type(of: value)) instead."
        let error = DecodingError.typeMismatch(
            T.self,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: description
            )
        )
        return try castOrThrow(T.self, value, error: error)
    }

    func unbox<T: Decodable>(_ value: Any, as type: T.Type) throws -> T {
        do {
            var value = value
            switch decodeTypeStrategy {
            case .strict: break
            case .loose:
                if let val = transformOrDefault(type, value: value, decoder: self) {
                    value = val
                }
            }
            return try unboxRawType(value, as: T.self)
        } catch {
            storage.push(container: value)
            defer {
                storage.popContainer()
            }
            return try T(from: self)
        }
    }

    func lastContainer<T>(forType type: T.Type) throws -> Any {
        guard let value = storage.last else {
            let description = "Expected \(type) but found nil value instead."
            let error = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: description
            )
            throw DecodingError.valueNotFound(type, error)
        }
        return value
    }

    func notFound(key: CodingKey) -> DecodingError {
        let error = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."
        )
        return DecodingError.keyNotFound(key, error)
    }
}

public extension DictionaryDecoder {
    /// Decodes a top-level value of the given type from the given Dictionary representation.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - container: The value to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: An error if any value throws an error during decoding.
    func decode<T: Decodable>(_ type: T.Type, from container: Any) throws -> T {
        return try unbox(container, as: T.self)
    }
}

func convertFromSnakeCase(_ stringKey: String) -> String {
    guard !stringKey.isEmpty else { return stringKey }

    // Find the first non-underscore character
    guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
        // Reached the end without finding an _
        return stringKey
    }

    // Find the last non-underscore character
    var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
    while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
        stringKey.formIndex(before: &lastNonUnderscore)
    }

    let keyRange = firstNonUnderscore...lastNonUnderscore
    let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
    let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex

    let components = stringKey[keyRange].split(separator: "_")
    let joinedString: String
    if components.count == 1 {
        // No underscores in key, leave the word as is - maybe already camel cased
        joinedString = String(stringKey[keyRange])
    } else {
        joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized })
            .joined()
    }

    // Do a cheap isEmpty check before creating and appending potentially empty strings
    let result: String
    if leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty {
        result = joinedString
    } else if !leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty {
        // Both leading and trailing underscores
        result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
    } else if !leadingUnderscoreRange.isEmpty {
        // Just leading
        result = String(stringKey[leadingUnderscoreRange]) + joinedString
    } else {
        // Just trailing
        result = joinedString + String(stringKey[trailingUnderscoreRange])
    }
    return result
}
