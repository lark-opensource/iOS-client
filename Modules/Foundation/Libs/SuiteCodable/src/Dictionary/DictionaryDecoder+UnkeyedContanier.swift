//
//  DictionaryDecoder+UnkeyedContanier.swift
//  Pods
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

extension DictionaryDecoder {
    final class UnkeyedContanier: UnkeyedDecodingContainer {
        private let decoder: DictionaryDecoder

        private let container: [Any]

        var codingPath: [CodingKey] {
            return decoder.codingPath
        }

        var count: Int? {
            return container.count
        }

        var isAtEnd: Bool {
            return currentIndex >= container.count
        }

        private(set) var currentIndex: Int = 0

        private var currentCodingPath: [CodingKey] {
            return decoder.codingPath + [AnyCodingKey(index: currentIndex)]
        }

        init(decoder: DictionaryDecoder, container: [Any]) {
            self.decoder = decoder
            self.container = container
        }

        private func checkIndex<T>(_ type: T.Type) throws {
            if isAtEnd {
                let error = DecodingError.Context(
                    codingPath: currentCodingPath,
                    debugDescription: "container is at end."
                )
                throw DecodingError.valueNotFound(T.self, error)
            }
        }

        private func _decode<T: Decodable>(_ type: T.Type) throws -> T {
            try checkIndex(type)

            decoder.codingPath.append(AnyCodingKey(index: currentIndex))
            defer {
                decoder.codingPath.removeLast()
                currentIndex += 1
            }
            return try decoder.unbox(container[currentIndex], as: T.self)
        }

        func decodeNil() throws -> Bool {
            try checkIndex(Any?.self)

            if self.container[self.currentIndex] is NSNull {
                self.currentIndex += 1
                return true
            }

            return false
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            return try _decode(type)
        }

        func decode(_ type: Int.Type) throws -> Int {
            return try _decode(type)
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            return try _decode(type)
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            return try _decode(type)
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            return try _decode(type)
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            return try _decode(type)
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            return try _decode(type)
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            return try _decode(type)
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            return try _decode(type)
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            return try _decode(type)
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            return try _decode(type)
        }

        func decode(_ type: Float.Type) throws -> Float {
            return try _decode(type)
        }

        func decode(_ type: Double.Type) throws -> Double {
            return try _decode(type)
        }

        func decode(_ type: String.Type) throws -> String {
            return try _decode(type)
        }

        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            return try _decode(type)
        }

        func nestedContainer<NestedKey: CodingKey>(
            keyedBy type: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey> {
            decoder.codingPath.append(AnyCodingKey(index: currentIndex))
            defer {
                decoder.codingPath.removeLast()
            }

            try checkIndex(UnkeyedContanier.self)

            let value = container[currentIndex]
            let dictionary = try castOrThrow([String: Any].self, value)

            currentIndex += 1
            return KeyedDecodingContainer(
                KeyedContainer<NestedKey>(decoder: decoder, container: dictionary)
            )
        }

        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            decoder.codingPath.append(AnyCodingKey(index: currentIndex))
            defer {
                decoder.codingPath.removeLast()
            }

            try checkIndex(UnkeyedContanier.self)

            let value = container[currentIndex]
            let array = try castOrThrow([Any].self, value)

            currentIndex += 1
            return UnkeyedContanier(decoder: decoder, container: array)
        }

        func superDecoder() throws -> Decoder {
            decoder.codingPath.append(AnyCodingKey(index: currentIndex))
            defer {
                decoder.codingPath.removeLast()
            }

            try checkIndex(UnkeyedContanier.self)

            let value = container[currentIndex]
            currentIndex += 1
            return DictionaryDecoder(container: value, codingPath: decoder.codingPath)
        }
    }
}
