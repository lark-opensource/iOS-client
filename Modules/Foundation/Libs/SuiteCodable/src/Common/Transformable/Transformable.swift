//
//  Transformable.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation

public protocol HasDefault {
    static func `default`() -> Self
}

protocol Transformable {
    static func transform(from object: Any) -> Self?
}

func transformOrDefault<T: Decodable>(_ type: T.Type, value: Any? = nil, decoder: DictionaryDecoder? = nil) -> Any? {
    if let value = value as? T {
        return value
    }

    if let value = value {
        // NOTE: 下面的语句只能在动态库中能够执行，因此SuiteCodable只能是动态库
        if let transformable = type as? Transformable.Type,
            let transformValue = transformable.transform(from: value) {
            return transformValue
        }

        if let decoder = decoder {
            decoder.storage.push(container: value)
            defer {
                decoder.storage.popContainer()
            }
            if let decodeValue = try? T(from: decoder) {
                return decodeValue
            }

        }
    }

    if let hasDefault = type as? HasDefault.Type {
        return hasDefault.default()
    }

    return value
}
