//
//  JSONString.swift
//  LarkWorkplaceModel
//
//  Created by Meng on 2022/11/6.
//

import Foundation

/// JSONString Codable descriptor.
///
/// parse JSON object represented by string.
/// - throws: `DecodingError.dataCorrupted` if convert stringValue to decode data failed.
public struct JSONString<Value: Codable>: Codable {

    /// JSON object represented by string.
    public let value: Value
    /// original string value
    public let stringValue: String

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let strValue = try container.decode(String.self)
        guard let data = strValue.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "decode JSONString from stringValue failed."
            ))
        }

        // Avoid codingPath truncated when creating new JSONDecoder,
        // which could result in error untraceable
        do {
            value = try JSONDecoder().decode(Value.self, from: data)
            stringValue = strValue
        } catch {
            throw DecodingError.typeMismatch(
                Value.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "json string inner struct decode error: \(error)"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
