//
//  DictionaryEncoder+SingleValueContainer.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

extension DictionaryEncoder {
    final class SingleValueContainer: SingleValueEncodingContainer {
        private let encoder: DictionaryEncoder

        var codingPath: [CodingKey] {
            return encoder.codingPath
        }

        private var storage: Storage {
            return encoder.storage
        }

        var count: Int { return storage.count }

        init(encoder: DictionaryEncoder) {
            self.encoder = encoder
        }

        private func push(_ value: Any) {
            guard var array = storage.popContainer() as? [Any] else {
                assertionFailure()
                return
            }
            array.append(value)
            storage.push(container: array)
        }

        func encodeNil() throws {
            storage.push(container: NSNull())
        }

        func encode(_ value: Bool) throws {
            storage.push(container: value)
        }

        func encode(_ value: Int) throws {
            storage.push(container: value)
        }

        func encode(_ value: Int8) throws {
            storage.push(container: value)
        }

        func encode(_ value: Int16) throws {
            storage.push(container: value)
        }

        func encode(_ value: Int32) throws {
            storage.push(container: value)
        }

        func encode(_ value: Int64) throws {
            storage.push(container: value)
        }

        func encode(_ value: UInt) throws {
            storage.push(container: value)
        }

        func encode(_ value: UInt8) throws {
            storage.push(container: value)
        }

        func encode(_ value: UInt16) throws {
            storage.push(container: value)
        }

        func encode(_ value: UInt32) throws {
            storage.push(container: value)
        }

        func encode(_ value: UInt64) throws {
            storage.push(container: value)
        }

        func encode(_ value: Float) throws {
            storage.push(container: value)
        }

        func encode(_ value: Double) throws {
            storage.push(container: value)
        }

        func encode(_ value: String) throws {
            storage.push(container: value)
        }

        func encode<T: Encodable>(_ value: T) throws {
            storage.push(container: try encoder.box(value))
        }
    }
}
