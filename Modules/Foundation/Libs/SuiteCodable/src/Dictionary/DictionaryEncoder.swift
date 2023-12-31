//
//  DictionaryEncoder.swift
//  Pods
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

open class DictionaryEncoder: Encoder {
    public var codingPath: [CodingKey] = []

    public var userInfo: [CodingUserInfoKey: Any] = [:]

    var storage = Storage()

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    private var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path
        // (even if it's a nil key from an unkeyed container).
        //
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path,
        // it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack,
        // we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them
        // (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }

    /// Initializes `self` with default strategies.
    public init() {}

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        // If an existing keyed container was already requested, return that one.
        let topContainer: NSMutableDictionary
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = NSMutableDictionary()
            self.storage.push(container: topContainer)
        } else {
            guard let container = self.storage.last as? NSMutableDictionary else {
                preconditionFailure(
                    "Attempt to push new keyed encoding container when already previously encoded at this path."
                )
            }
            topContainer = container
        }

        return KeyedEncodingContainer(
            KeyedContainer<Key>(encoder: self, container: topContainer)
        )
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: NSMutableArray
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = NSMutableArray()
            self.storage.push(container: topContainer)
        } else {
            guard let container = self.storage.containers.last as? NSMutableArray else {
                preconditionFailure(
                    "Attempt to push new unkeyed encoding container when already previously encoded at this path."
                )
            }

            topContainer = container
        }
        return UnkeyedContanier(encoder: self, container: topContainer)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContainer(encoder: self)
    }

    func box<T: Encodable>(_ value: T) throws -> Any {
        // NOTE: URL符合Codable协议，会当结构体再次处理，这里单独处理下
        let type = Swift.type(of: value)
        if type == URL.self {
            return (value as? URL)?.absoluteString ?? {
                #if DEBUG || ALPHA
                fatalError("unexpected")
                #else
                return ""
                #endif
            }()
        }

        try value.encode(to: self)
        return storage.popContainer()
    }
}

public extension DictionaryEncoder {
    /// Encodes the given top-level value and returns its Dictionary representation.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: A new `Dictionary` value
    /// - Throws: An error if any value throws an error during encoding.
    func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        do {
            return try castOrThrow([String: Any].self, try box(value))
        } catch {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Top-level \(T.self) did not encode any values.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes an array of objects
    ///
    /// - Parameter values: The array to encode.
    /// - Returns: A new array of `Dictionary`
    /// - Throws: An error if any value throws an error during encoding.
    func encode<T: Encodable>(_ values: [T]) throws -> [[String: Any]] {
        return try values.map { try self.encode($0) }
    }
}
