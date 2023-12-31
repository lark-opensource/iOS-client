//
//  DictionaryDecoder+KeyedContainer.swift
//  Pods
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

extension DictionaryDecoder {
    final class KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        private let decoder: DictionaryDecoder

        private let container: [String: Any]

        var codingPath: [CodingKey] {
            return decoder.codingPath
        }

        var allKeys: [Key] {
            return container.keys.compactMap { Key(stringValue: $0) }
        }

        init(decoder: DictionaryDecoder, container: [String: Any]) {
            self.decoder = decoder

            switch decoder.keyDecodingStrategy {
            case .useDefaultKeys:
                self.container = container
            case .convertFromSnakeCase:
                self.container = Dictionary(
                    container.map { key, value in
                        (convertFromSnakeCase(key), value)
                    },
                    uniquingKeysWith: { (first, _) in first }
                )
            }
        }

        func contains(_ key: Key) -> Bool {
            return container[key.stringValue] != nil
        }

        private func find(forKey key: CodingKey) -> Any? {
            return container[key.stringValue]
        }

        private func _decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            var value: Any
            switch decoder.decodeTypeStrategy {
            case .strict:
                guard let val = find(forKey: key) else {
                    throw decoder.notFound(key: key)
                }
                value = val
            case .loose:
                if let val = find(forKey: key) {
                    value = val
                } else if let val = transformOrDefault(type) {
                    value = val
                } else {
                    throw decoder.notFound(key: key)
                }
            }
            decoder.codingPath.append(key)
            defer {
                decoder.codingPath.removeLast()
            }

            return try decoder.unbox(value, as: T.self)
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            guard let entry = find(forKey: key) else {
                throw decoder.notFound(key: key)
            }

            return entry is NSNull
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            return try _decode(type, forKey: key)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            return try _decode(type, forKey: key)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            return try _decode(type, forKey: key)
        }

        private func _superDecoder(forKey key: CodingKey = AnyCodingKey.super) throws -> Decoder {
            decoder.codingPath.append(key)
            defer {
                decoder.codingPath.removeLast()
            }

            guard let value = find(forKey: key) else {
                throw decoder.notFound(key: key)
            }
            return DictionaryDecoder(container: value, codingPath: decoder.codingPath)
        }

        func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            decoder.codingPath.append(key)
            defer {
                decoder.codingPath.removeLast()
            }

            guard let value = find(forKey: key) else {
                throw decoder.notFound(key: key)
            }
            let dictionary = try decoder.unboxRawType(value, as: [String: Any].self)
            return KeyedDecodingContainer(
                KeyedContainer<NestedKey>(decoder: decoder, container: dictionary)
            )
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            decoder.codingPath.append(key)
            defer {
                decoder.codingPath.removeLast()
            }

            guard let value = find(forKey: key) else {
                throw decoder.notFound(key: key)
            }
            let array = try decoder.unboxRawType(value, as: [Any].self)
            return UnkeyedContanier(decoder: decoder, container: array)
        }

        func superDecoder() throws -> Decoder {
            return try _superDecoder()
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return try _superDecoder(forKey: key)
        }
    }
}
