//
//  DictionaryEncoder+UnkeyedContanier.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

extension DictionaryEncoder {
    final class UnkeyedContanier: UnkeyedEncodingContainer {
        private let encoder: DictionaryEncoder

        /// A reference to the container we're writing to.
        private let container: NSMutableArray

        var codingPath: [CodingKey] {
            return encoder.codingPath
        }

        var count: Int {
            return container.count
        }

        init(encoder: DictionaryEncoder, container: NSMutableArray) {
            self.encoder = encoder
            self.container = container
        }

        private func push(_ value: Any) {
            self.container.add(value)
        }

        func encodeNil() throws {
            push(NSNull())
        }

        func encode(_ value: Bool) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Int) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Int8) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Int16) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Int32) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Int64) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: UInt) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: UInt8) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: UInt16) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: UInt32) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: UInt64) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Float) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: Double) throws {
            push(try encoder.box(value))
        }

        func encode(_ value: String) throws {
            push(try encoder.box(value))
        }

        func encode<T: Encodable>(_ value: T) throws {
            encoder.codingPath.append(AnyCodingKey(index: count))
            defer {
                encoder.codingPath.removeLast()
            }
            push(try encoder.box(value))
        }

        func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.codingPath.append(AnyCodingKey(index: count))
            defer {
                encoder.codingPath.removeLast()
            }

            let dictionary = NSMutableDictionary()
            self.container.add(dictionary)
            return KeyedEncodingContainer(
                KeyedContainer<NestedKey>(encoder: encoder, container: dictionary)
            )
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            encoder.codingPath.append(AnyCodingKey(index: count))
            defer {
                encoder.codingPath.removeLast()
            }

            let array = NSMutableArray()
            self.container.add(array)
            return UnkeyedContanier(encoder: encoder, container: array)

        }

        func superEncoder() -> Encoder {
            return encoder
        }
    }
}
