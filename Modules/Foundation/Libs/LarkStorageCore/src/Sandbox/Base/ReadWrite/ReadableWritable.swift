//
//  ReadableWritable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public struct SBReadingContext {
    enum Key: String {
        case stringEncoding
        case dataReadingOptions
    }

    private var inner: [String: Any]

    static let empty = SBReadingContext(inner: [:])

    static func key(_ key: Key, value: Any) -> Self {
        self.init(inner: [key.rawValue: value])
    }

    func value(forKey key: Key) -> Any? {
        return inner[key.rawValue]
    }
}

public struct SBWritingContext {
    enum Key: String {
        case atomic
        case stringEncoding
        case dataWritingOptions
    }

    private var inner: [String: Any]

    static let empty = SBWritingContext(inner: [:])

    static func key(_ key: Key, value: Any) -> Self {
        self.init(inner: [key.rawValue: value])
    }

    mutating func set(_ value: Any, forKey key: Key) {
        inner[key.rawValue] = value
    }

    func value(forKey key: Key) -> Any? {
        return inner[key.rawValue]
    }
}

extension SBWritingContext {
    @inline(__always)
    static func atomically(_ bool: Bool) -> Self {
        return .key(.atomic, value: bool)
    }
    
    var atomically: Bool {
        (self.value(forKey: .atomic) as? Bool) ?? false
    }
}

public protocol SBBaseReadable { }
public protocol SBBaseWritable { }

protocol SBPathReadable: SBBaseReadable {
    typealias RawPath = String
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self
}

protocol SBPathWritable: SBBaseWritable {
    typealias RawPath = String
    func sb_write(to path: RawPath, with context: SBWritingContext) throws
}

typealias SBPathConvertible = SBPathReadable & SBPathWritable

protocol SBDataConvertible: SBBaseReadable, SBBaseWritable {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self

    func sb_to_data(with context: SBWritingContext) throws -> Data
}
