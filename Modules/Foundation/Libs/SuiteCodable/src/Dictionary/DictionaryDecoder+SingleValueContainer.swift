//
//  DictionaryDecoder+SingleValueContainer.swift
//  Pods
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

extension DictionaryDecoder {
    final class SingleValueContainer: SingleValueDecodingContainer {
        private let decoder: DictionaryDecoder

        var codingPath: [CodingKey] {
            return decoder.codingPath
        }

        init(decoder: DictionaryDecoder) {
            self.decoder = decoder
        }

        private func _decode<T>(_ type: T.Type) throws -> T {
            let container = try decoder.lastContainer(forType: type)
            return try decoder.unboxRawType(container, as: T.self)
        }

        func decodeNil() -> Bool {
            return decoder.storage.last == nil
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
    }
}
