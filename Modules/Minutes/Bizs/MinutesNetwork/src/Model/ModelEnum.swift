//
//  ModelEnum.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/4/9.
//

import Foundation

public protocol ModelEnum: Codable, RawRepresentable {
    static var fallbackValue: Self { get }
}

extension KeyedDecodingContainer {
    // This is used to override the default decoding behavior for `EmptyFallbackDecodableWrapper` to allow a value to avoid a missing key Error
    public func decode<T: ModelEnum>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T.RawValue: Decodable {
        if let raw = try? decodeIfPresent(T.RawValue.self, forKey: key), let value = T(rawValue: raw) {
            return value
        } else {
            return T.fallbackValue
        }
    }
}
