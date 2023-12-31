//
//  DictionaryEncoder+KeyedContainer.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

extension DictionaryEncoder {
    final class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: DictionaryEncoder

        private let container: NSMutableDictionary

        var codingPath: [CodingKey] {
            return encoder.codingPath
        }

        init(encoder: DictionaryEncoder, container: NSMutableDictionary) {
            self.encoder = encoder
            self.container = container
        }

        private func set<T: CodingKey>(_ value: Any, forKey key: T) {
            self.container[key.stringValue] = value
        }

        func encodeNil(forKey key: Key) throws {
            set(NSNull(), forKey: key)
        }

        func encode(_ value: Bool, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Int, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Int8, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Int16, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Int32, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Int64, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: UInt, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: UInt8, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: UInt16, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: UInt32, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: UInt64, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Float, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: Double, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode(_ value: String, forKey key: Key) throws {
            set(value, forKey: key)
        }

        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer {
                encoder.codingPath.removeLast()
            }
            set(try encoder.box(value), forKey: key)
        }

        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey> {
            let containerKey = key.stringValue
            let dictionary: NSMutableDictionary
            if let existingContainer = self.container[containerKey] {
                precondition(
                    existingContainer is NSMutableDictionary,
                    "Nested KeyedEncodingContainer for key \"\(containerKey)\" is invalid: " +
                    "non-keyed container already encoded for this key"
                )
                dictionary = (existingContainer as? NSMutableDictionary) ?? .init()
            } else {
                dictionary = NSMutableDictionary()
                self.container[containerKey] = dictionary
            }

            encoder.codingPath.append(key)
            defer {
                encoder.codingPath.removeLast()
            }
            return KeyedEncodingContainer(
                KeyedContainer<NestedKey>(encoder: encoder, container: dictionary)
            )
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            let containerKey = key.stringValue
            let array: NSMutableArray
            if let existingContainer = self.container[containerKey] {
                precondition(
                    existingContainer is NSMutableArray,
                    "Nested UnkeyedEncodingContainer for key \"\(containerKey)\" is invalid: " +
                    "keyed container/single value already encoded for this key"
                )
                array = (existingContainer as? NSMutableArray) ?? .init()
            } else {
                array = NSMutableArray()
                self.container[containerKey] = array
            }

            encoder.codingPath.append(key)
            defer {
                encoder.codingPath.removeLast()
            }
            return UnkeyedContanier(encoder: encoder, container: array)
        }

        func superEncoder() -> Encoder {
            return encoder
        }

        func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
}
