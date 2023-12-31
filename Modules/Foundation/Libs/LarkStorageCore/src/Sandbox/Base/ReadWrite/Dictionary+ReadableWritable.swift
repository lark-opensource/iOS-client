//
//  Dictionary+ReadableWritable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension Dictionary: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self {
        guard
            let contents = NSDictionary(contentsOfFile: path),
            let dict = contents as? Dictionary
        else {
            throw SandboxError.typeRead(type: "Dictionary", message: "path: \(path)")
        }
        return dict
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        guard (self as NSDictionary).write(toFile: path, atomically: context.atomically) else {
            throw SandboxError.typeWrite(type: "Dictionary", message: "path: \(path)")
        }
    }
}

extension Dictionary: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self {
        let contents = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let dict = contents as? Dictionary else {
            throw SandboxError.typeRead(type: "Dictionary", message: "stream mode")
        }
        return dict
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        return try PropertyListSerialization.data(fromPropertyList: self, format: .xml, options: .zero)
    }
}

final class NSDictionaryWrapper {
    var inner: NSDictionary
    init(inner: NSDictionary) {
        self.inner = inner
    }
}

extension NSDictionaryWrapper: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self {
        guard
            let contents = NSDictionary(contentsOfFile: path)
        else {
            throw SandboxError.typeRead(type: "NSDictionary", message: "path: \(path)")
        }
        return Self(inner: contents)
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        guard inner.write(toFile: path, atomically: context.atomically) else {
            throw SandboxError.typeWrite(type: "NSDictionary", message: "path: \(path)")
        }
    }
}

extension NSDictionaryWrapper: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self {
        let contents = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let dict = contents as? NSDictionary else {
            throw SandboxError.typeRead(type: "NSDictionary", message: "stream mode")
        }
        return Self(inner: dict)
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        return try PropertyListSerialization.data(fromPropertyList: self.inner, format: .xml, options: .zero)
    }
}
